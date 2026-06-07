#include "unity_fixture.h"
#include "ControlSystemSpy.h"

TEST_GROUP(ControlSystemSpy);

static void checkCmd(double cmdx, double cmdy, CMD_2D cmd)
{
    DOUBLES_EQUAL(cmdx, cmd.cmd_x, 0);
    DOUBLES_EQUAL(cmdy, cmd.cmd_y, 0);    
}

TEST_SETUP(ControlSystemSpy)
{
    ControlSystem_Create();
}

TEST_TEAR_DOWN(ControlSystemSpy)
{
}

TEST(ControlSystemSpy, StartHere)
{
    // TEST_FAIL_MESSAGE("Start Here");
}

TEST(ControlSystemSpy, CreateUnknownStatus)
{

    CMD_2D a;
    LONGS_EQUAL(FAKECONTROL_UNKNOWN,
                ControlSystemSpy_GetCmd(&a));
}

TEST(ControlSystemSpy, SetStatus)
{

    CMD_2D a = {.cmd_x = 0.0, .cmd_y = 0.0};

    ControlSystem_SendCmd(a);

    CMD_2D b;
    LONGS_EQUAL(FAKECONTROL_SET,
                ControlSystemSpy_GetCmd(&b));
}

TEST(ControlSystemSpy, SetCmdGetCmd)
{

    CMD_2D cmd = {.cmd_x = 5.0, .cmd_y = 10.0};

    ControlSystem_SendCmd(cmd);

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    checkCmd(5.0, 10.0, a_cmd);
}