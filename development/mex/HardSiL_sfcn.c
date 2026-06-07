#define S_FUNCTION_NAME HardSiL_sfcn
#define S_FUNCTION_LEVEL 2
#define MDL_START

#include "simstruc.h"
#include "ControlSystem.h"

#define WIN32_LEAN_AND_MEAN

#include "windows.h"
#include "winsock2.h"
#include "ws2tcpip.h"

#include "stdlib.h"

#define DEFAULT_HOST "localhost"
#define DEFAULT_PORT "27015"
#define RECV_TIMEOUT_MS 1000

typedef struct PACK_48B
{
    double rm_x;
    double rm_y;
    double vm_x;
    double vm_y;
    double rp_x;
    double rp_y;
} PACK_48B;

static SOCKET ConnectSocket = INVALID_SOCKET;

static int recv_all(SOCKET s, char *buf, int n)
{
    int total = 0;
    while (total < n)
    {
        int r = recv(s, buf + total, n - total, 0);
        if (r <= 0)
            return r;
        total += r;
    }
    return total;
}

// FIX: simétrico para send — defensivo
static int send_all(SOCKET s, const char *buf, int n)
{
    int total = 0;
    while (total < n)
    {
        int r = send(s, buf + total, n - total, 0);
        if (r == SOCKET_ERROR)
            return r;
        total += r;
    }
    return total;
}

static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, 0);
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S))
    {
        return; /* Parameter mismatch reported by the Simulink engine*/
    }

    if (!ssSetNumInputPorts(S, 3))
        return;
    ssSetInputPortWidth(S, 0, 2);
    ssSetInputPortWidth(S, 1, 2);
    ssSetInputPortWidth(S, 2, 2);

    ssSetInputPortDirectFeedThrough(S, 0, 1);
    ssSetInputPortDirectFeedThrough(S, 1, 1);
    ssSetInputPortDirectFeedThrough(S, 2, 1);

    ssSetInputPortRequiredContiguous(S, 0, 1);
    ssSetInputPortRequiredContiguous(S, 1, 1);
    ssSetInputPortRequiredContiguous(S, 2, 1);

    if (!ssSetNumOutputPorts(S, 1))
        return;
    ssSetOutputPortWidth(S, 0, 2);

    ssSetNumSampleTimes(S, 1);

    /* Take care when specifying exception free code - see sfuntmpl.doc */
    ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE);
}

static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
}

static void mdlStart(SimStruct *S)
{
    WSADATA wsaData;
    struct addrinfo *result = NULL, *ptr = NULL, hints;
    int iResult;

    iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0)
    {
        // FIX: reporte de error explícito a Simulink + return;
        ssSetErrorStatus(S, "Hard-SIL: WSAStartup failed");
        return;
    }

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    iResult = getaddrinfo(DEFAULT_HOST, DEFAULT_PORT, &hints, &result);
    if (iResult != 0)
    {
        WSACleanup();
        ssSetErrorStatus(S, "Hard-SIL: getaddrinfo failed");
        return;
    }

    for (ptr = result; ptr != NULL; ptr = ptr->ai_next)
    {
        ConnectSocket = socket(ptr->ai_family, ptr->ai_socktype, ptr->ai_protocol);
        if (ConnectSocket == INVALID_SOCKET)
        {
            freeaddrinfo(result);
            WSACleanup();
            ssSetErrorStatus(S, "Hard-SIL: socket() failed");
            return;
        }

        iResult = connect(ConnectSocket, ptr->ai_addr, (int)ptr->ai_addrlen);
        if (iResult == SOCKET_ERROR)
        {
            closesocket(ConnectSocket);
            ConnectSocket = INVALID_SOCKET;
            continue;
        }
        break;
    }

    freeaddrinfo(result);

    if (ConnectSocket == INVALID_SOCKET)
    {
        WSACleanup();
        ssSetErrorStatus(S, "Hard-SIL: no se pudo conectar al target (Renode)");
        return;
    }

    // FIX: timeout de recepción para evitar cuelgue indefinido si el target no responde
    DWORD timeout = RECV_TIMEOUT_MS;
    if (setsockopt(ConnectSocket, SOL_SOCKET, SO_RCVTIMEO,
                   (const char *)&timeout, sizeof(timeout)) == SOCKET_ERROR)
    {
        closesocket(ConnectSocket);
        WSACleanup();
        ssSetErrorStatus(S, "Hard-SIL: setsockopt(SO_RCVTIMEO) failed");
        return;
    }
}

static void mdlOutputs(SimStruct *S, int_T tid)
{
    // FIX: eliminada variable 'i' no usada
    const real_T *r_m = ssGetInputPortRealSignal(S, 0);
    const real_T *v_m = ssGetInputPortRealSignal(S, 1);
    const real_T *r_p = ssGetInputPortRealSignal(S, 2);
    real_T *a_cmd = ssGetOutputPortRealSignal(S, 0);

    PACK_48B pack;
    CMD_2D con_cmd;

    pack.rm_x = r_m[0];
    pack.rm_y = r_m[1];
    pack.vm_x = v_m[0];
    pack.vm_y = v_m[1];
    pack.rp_x = r_p[0];
    pack.rp_y = r_p[1];

    if (send_all(ConnectSocket, (const char *)&pack, sizeof pack) == SOCKET_ERROR)
    {
        ssSetErrorStatus(S, "Hard-SIL: send error");
        return;
    }

    int r = recv_all(ConnectSocket, (char *)&con_cmd, sizeof con_cmd);
    if (r == sizeof con_cmd)
    {
        a_cmd[0] = con_cmd.cmd_x;
        a_cmd[1] = con_cmd.cmd_y;
    }
    else if (r == SOCKET_ERROR)
    {
        int err = WSAGetLastError();
        if (err == WSAETIMEDOUT)
        {
            ssSetErrorStatus(S, "Hard-SIL: timeout esperando respuesta del target");
        }
        else
        {
            ssSetErrorStatus(S, "Hard-SIL: recv error");
        }
        return;
    }
    else // r == 0: conexión cerrada por el peer
    {
        ssSetErrorStatus(S, "Hard-SIL: conexión cerrada por el target");
        return;
    }
}

static void mdlTerminate(SimStruct *S)
{
    if (ConnectSocket != INVALID_SOCKET)
    {
        closesocket(ConnectSocket);
        ConnectSocket = INVALID_SOCKET;
    }
    WSACleanup();
}

#ifdef MATLAB_MEX_FILE /* Is this file being compiled as a MEX-file? */
#include "simulink.c"  /* MEX-file interface mechanism */
#else
#include "cg_sfun.h" /* Code generation registration function */
#endif