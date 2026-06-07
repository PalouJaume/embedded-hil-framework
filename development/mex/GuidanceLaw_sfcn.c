#define S_FUNCTION_NAME GuidanceLaw_sfcn
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"
#include "GuidanceLaw.h"
#include "ControlSystem.h"
#include "NavigationSystem.h"
#include "Planner.h"

// ESTO ME PUEDE DAR PROBLEMAS SI HAY MULTIPLES INSTANCIAS
static POS_2D plan_p;
static STATE_2D nav_state;
static CMD_2D con_cmd;

void ControlSystem_SendCmd(CMD_2D a)
{
   con_cmd = a; 
}

void NavigationSystem_GetState(STATE_2D *state)
{
    *state = nav_state;
}

void Planner_GetPoint(POS_2D *pos)
{
    *pos = plan_p;
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

static void mdlOutputs(SimStruct *S, int_T tid)
{
    int_T i;
    const real_T *r_m = ssGetInputPortRealSignal(S, 0);
    const real_T *v_m = ssGetInputPortRealSignal(S, 1);
    const real_T *r_p = ssGetInputPortRealSignal(S, 2);
    real_T *a_cmd = ssGetOutputPortRealSignal(S, 0);

    plan_p.x = r_p[0];
    plan_p.y = r_p[1];

    nav_state.r_x = r_m[0];
    nav_state.r_y = r_m[1];
    nav_state.v_x = v_m[0];
    nav_state.v_y = v_m[1];

    GuidanceLaw_Cmd();

    a_cmd[0] = con_cmd.cmd_x;
    a_cmd[1] = con_cmd.cmd_y;
}

static void mdlTerminate(SimStruct *S) {}

#ifdef MATLAB_MEX_FILE /* Is this file being compiled as a MEX-file? */
#include "simulink.c"  /* MEX-file interface mechanism */
#else
#include "cg_sfun.h" /* Code generation registration function */
#endif