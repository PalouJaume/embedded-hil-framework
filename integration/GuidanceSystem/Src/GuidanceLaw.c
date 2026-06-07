#include "GuidanceLaw.h"

#include "ControlSystem.h"
#include "Planner.h"
#include "NavigationSystem.h"

#include "math.h"

void GuidanceLaw_Create(void)
{
}

void GuidanceLaw_Destroy(void)
{
}

void GuidanceLaw_Cmd(void)
{
    CMD_2D a_cmd = {.cmd_x = 0.0, .cmd_y = 0.0};

    POS_2D p;
    Planner_GetPoint(&p);

    STATE_2D state;
    NavigationSystem_GetState(&state);

    double L1X = p.x - state.r_x;
    double L1Y = p.y - state.r_y;
    double L1 = sqrt(L1X * L1X + L1Y * L1Y);

    double VX = state.v_x;
    double VY = state.v_y;
    double V = sqrt(VX * VX + VY * VY);

    if (L1 < 1 || V < 1)
    {
        ControlSystem_SendCmd(a_cmd);
        return;
    }

    double as_cmd = 2 * V * (VX * L1Y - VY * L1X) / (L1 * L1);

    a_cmd.cmd_x = as_cmd * (-VY / V);
    a_cmd.cmd_y = as_cmd * (VX / V);

    ControlSystem_SendCmd(a_cmd);
}
