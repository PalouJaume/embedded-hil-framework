#include "ControlSystemSpy.h"

static FAKECONTROL_STATUS status;
static CMD_2D cmd;

void ControlSystem_Create(void)
{
    status = FAKECONTROL_UNKNOWN;
}

void ControlSystem_SendCmd(CMD_2D a)
{
    status = FAKECONTROL_SET;
    cmd = a;
}

FAKECONTROL_STATUS ControlSystemSpy_GetCmd(CMD_2D* a)
{
    a->cmd_x = cmd.cmd_x;
    a->cmd_y = cmd.cmd_y;
    return status;
}
