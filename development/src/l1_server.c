#undef UNICODE

#define WIN32_LEAN_AND_MEAN

#include "Windows.h"
#include "WinSock2.h"
#include "WS2tcpip.h"
#include "stdlib.h"
#include "stdio.h"
#include "limits.h"
#include "math.h"

// Need to link with Ws2_32.lib
#pragma comment(lib, "Ws2_32.lib")

#define DEFAULT_BUFLEN 512
#define DEFAULT_PORT "27015"

typedef struct CMD_2D
{
    double x;
    double y;
} CMD_2D;

typedef struct PACK_48B
{
    double rm_x;
    double rm_y;
    double vm_x;
    double vm_y;
    double rp_x;
    double rp_y;
} PACK_48B;

void print_pack(PACK_48B pack)
{
    printf("Pack: {\n");
    printf("    rm_x: %f\n", pack.rm_x);
    printf("    rm_y: %f\n", pack.rm_y);
    printf("    vm_x: %f\n", pack.vm_x);
    printf("    vm_y: %f\n", pack.vm_y);
    printf("    rp_x: %f\n", pack.rp_x);
    printf("    rp_y: %f\n", pack.rp_y);
    printf("}\n");
}

int main(int argc, char *argv[])
{
    CMD_2D a_cmd;

    // 1. Create a WSADATA object called wsaData
    WSADATA wsaData;
    int iResult;

    SOCKET ListenSocket = INVALID_SOCKET;
    SOCKET ClientSocket = INVALID_SOCKET;

    struct addrinfo *result = NULL;
    struct addrinfo hints;

    int iSendResult;
    int recvbuflen = DEFAULT_BUFLEN;
    char recvbuf[DEFAULT_BUFLEN];

    char ipstr[INET6_ADDRSTRLEN];

    // 2. Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0)
    {
        printf("WSAStartup failed: %d\n", iResult);
        return 1;
    }

    // 3. Set addrinfo struct
    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;

    iResult = getaddrinfo(NULL, DEFAULT_PORT, &hints, &result);
    if (iResult != 0)
    {
        printf("getaddrinfo failed: %d\n", iResult);
        WSACleanup();
        return 1;
    }

    for (struct addrinfo *p = result; p != NULL; p = p->ai_next)
    {
        inet_ntop(p->ai_family, &((struct sockaddr_in *)p->ai_addr)->sin_addr, ipstr, sizeof ipstr);
        printf("[INFO] Listening %s/%s\n", ipstr, DEFAULT_PORT);
    }

    // 4. Create a SOCKET object called ListenSocket for the server to listen for client connections.
    ListenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    if (ListenSocket == INVALID_SOCKET)
    {
        printf("Error at socket(): %d\n", WSAGetLastError());
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }

    // 5. Bind socket to port
    iResult = bind(ListenSocket, result->ai_addr, (int)result->ai_addrlen);
    if (iResult == SOCKET_ERROR)
    {
        printf("bind failed with error: %d\n", WSAGetLastError());
        freeaddrinfo(result);
        closesocket(ListenSocket);
        WSACleanup();
        return -1;
    }

    freeaddrinfo(result);

    // 6. Listening on a Socket
    iResult = listen(ListenSocket, SOMAXCONN);
    if (iResult == SOCKET_ERROR)
    {
        printf("Listen failed with error: %d\n", WSAGetLastError());
        closesocket(ListenSocket);
        WSACleanup();
        return 1;
    }

    // 7. Accepting a connection
    ClientSocket = accept(ListenSocket, NULL, NULL);
    if (ClientSocket == INVALID_SOCKET)
    {
        printf("accept failed: %d\n", WSAGetLastError());
        closesocket(ListenSocket);
        WSACleanup();
        return 1;
    }

    closesocket(ListenSocket);

    // 8. Receiving and Sending Data on the Server
    do
    {
        iResult = recv(ClientSocket, recvbuf, recvbuflen, 0);
        if (iResult > 0)
        {
            printf("Bytes received: %d\n", iResult);
            if (iResult == 48)
            {
                print_pack(*(PACK_48B *)recvbuf);
            }

            a_cmd.x = 0.1234;
            a_cmd.y = 0.5648;

            // Send fake command
            iSendResult = send(ClientSocket, (void *)&a_cmd, sizeof a_cmd, 0);
            if (iSendResult == SOCKET_ERROR)
            {
                printf("send failed: %d\n", WSAGetLastError());
                closesocket(ClientSocket);
                WSACleanup();
                return 1;
            }
            printf("Bytes sent: %d\n", iSendResult);
        }
        else if (iResult == 0)
            printf("Connection closing...\n");
        else
        {
            printf("recv failed: %d", WSAGetLastError());
            closesocket(ClientSocket);
            WSACleanup();
            return 1;
        }
    } while (iResult > 0);

    // 9. Disconnecting the Server
    iResult = shutdown(ClientSocket, SD_SEND);
    if (iResult == SOCKET_ERROR)
    {
        printf("shutdown failed: %d\n", WSAGetLastError());
        closesocket(ClientSocket);
        WSACleanup();
        return 1;
    }

    // cleanup
    closesocket(ClientSocket);
    WSACleanup();

    return 0;
}