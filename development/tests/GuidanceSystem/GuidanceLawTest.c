#include "unity_fixture.h"
#include "GuidanceLaw.h"

#include "ControlSystemSpy.h"
#include "FakeNavigationSystem.h"
#include "FakePlanner.h"

#include "l1_test_vectors_20260509_215132.h"

#define ACMD_TOL 1e-4f   

TEST_GROUP(GuidanceLaw);

TEST_SETUP(GuidanceLaw)
{
}

TEST_TEAR_DOWN(GuidanceLaw)
{
}

TEST(GuidanceLaw, StartHere)
{
    // TEST_FAIL_MESSAGE("Start Here");
}

TEST(GuidanceLaw, OnTrackNullCmd)
{
    FakePlanner_SetPoint(10.0, 10.0);
    FakeNavigationSystem_SetState(10.0, 10.0, 30.0, 40.0);

    GuidanceLaw_Cmd();

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    DOUBLES_EQUAL(0.0, a_cmd.cmd_x, 0);
    DOUBLES_EQUAL(0.0, a_cmd.cmd_y, 0);
}

TEST(GuidanceLaw, ZeroVelocityNullCmd)
{
    FakePlanner_SetPoint(10.0, 10.0);
    FakeNavigationSystem_SetState(50.0, 90.0, 0.0, 0.0);

    GuidanceLaw_Cmd();

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    DOUBLES_EQUAL(0.0, a_cmd.cmd_x, 0);
    DOUBLES_EQUAL(0.0, a_cmd.cmd_y, 0);    
}

TEST(GuidanceLaw, AlignNullCmd)
{
    FakePlanner_SetPoint(10.0, 10.0);
    FakeNavigationSystem_SetState(10.0, 20.0, 0.0, 10.0);

    GuidanceLaw_Cmd();

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    DOUBLES_EQUAL(0.0, a_cmd.cmd_x, 0);
    DOUBLES_EQUAL(0.0, a_cmd.cmd_y, 0);    
}

TEST(GuidanceLaw, Line_T30)
{
    FakePlanner_SetPoint(R_P_LINE_T30_X, R_P_LINE_T30_Y);
    FakeNavigationSystem_SetState(R_F_LINE_T30_X, R_F_LINE_T30_Y,
                                  V_F_LINE_T30_X, V_F_LINE_T30_Y);

    GuidanceLaw_Cmd();

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    DOUBLES_EQUAL(A_CMD_LINE_T30_X, a_cmd.cmd_x, ACMD_TOL);
    DOUBLES_EQUAL(A_CMD_LINE_T30_Y, a_cmd.cmd_y, ACMD_TOL);
}

TEST(GuidanceLaw, Sinusoid_T60)
{
    FakePlanner_SetPoint(R_P_SINUSOID_T60_X, R_P_SINUSOID_T60_Y);
    FakeNavigationSystem_SetState(R_F_SINUSOID_T60_X, R_F_SINUSOID_T60_Y,
                                  V_F_SINUSOID_T60_X, V_F_SINUSOID_T60_Y);

    GuidanceLaw_Cmd();

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    DOUBLES_EQUAL(A_CMD_SINUSOID_T60_X, a_cmd.cmd_x, ACMD_TOL);
    DOUBLES_EQUAL(A_CMD_SINUSOID_T60_Y, a_cmd.cmd_y, ACMD_TOL);
}

TEST(GuidanceLaw, Circle_T0)
{
    FakePlanner_SetPoint(R_P_CIRCLE_T0_X, R_P_CIRCLE_T0_Y);
    FakeNavigationSystem_SetState(R_F_CIRCLE_T0_X, R_F_CIRCLE_T0_Y,
                                  V_F_CIRCLE_T0_X, V_F_CIRCLE_T0_Y);

    GuidanceLaw_Cmd();

    CMD_2D a_cmd;
    ControlSystemSpy_GetCmd(&a_cmd);

    DOUBLES_EQUAL(A_CMD_CIRCLE_T0_X, a_cmd.cmd_x, ACMD_TOL);
    DOUBLES_EQUAL(A_CMD_CIRCLE_T0_Y, a_cmd.cmd_y, ACMD_TOL);
}

TEST(GuidanceLaw, Circle_RandomSamples)
{
    CMD_2D a_cmd;
    int i;

    for (i = 0; i < N_SAMPLES_CIRCLE; i++)
    {
        FakePlanner_SetPoint(R_P_CIRCLE_SAMPLES[i][0], R_P_CIRCLE_SAMPLES[i][1]);
        FakeNavigationSystem_SetState(R_F_CIRCLE_SAMPLES[i][0], R_F_CIRCLE_SAMPLES[i][1],
                                      V_F_CIRCLE_SAMPLES[i][0], V_F_CIRCLE_SAMPLES[i][1]);

        GuidanceLaw_Cmd();
        ControlSystemSpy_GetCmd(&a_cmd);

        DOUBLES_EQUAL(A_CMD_CIRCLE_SAMPLES[i][0], a_cmd.cmd_x, ACMD_TOL);
        DOUBLES_EQUAL(A_CMD_CIRCLE_SAMPLES[i][1], a_cmd.cmd_y, ACMD_TOL);
    }
}

TEST(GuidanceLaw, Line_RandomSamples)
{
    CMD_2D a_cmd;
    int i;

    for (i = 0; i < N_SAMPLES_LINE; i++)
    {
        FakePlanner_SetPoint(R_P_LINE_SAMPLES[i][0], R_P_LINE_SAMPLES[i][1]);
        FakeNavigationSystem_SetState(R_F_LINE_SAMPLES[i][0], R_F_LINE_SAMPLES[i][1],
                                      V_F_LINE_SAMPLES[i][0], V_F_LINE_SAMPLES[i][1]);

        GuidanceLaw_Cmd();
        ControlSystemSpy_GetCmd(&a_cmd);

        DOUBLES_EQUAL(A_CMD_LINE_SAMPLES[i][0], a_cmd.cmd_x, ACMD_TOL);
        DOUBLES_EQUAL(A_CMD_LINE_SAMPLES[i][1], a_cmd.cmd_y, ACMD_TOL);
    }
}

TEST(GuidanceLaw, Sinusoid_RandomSamples)
{
    CMD_2D a_cmd;
    int i;

    for (i = 0; i < N_SAMPLES_LINE; i++)
    {
        FakePlanner_SetPoint(R_P_SINUSOID_SAMPLES[i][0], R_P_SINUSOID_SAMPLES[i][1]);
        FakeNavigationSystem_SetState(R_F_SINUSOID_SAMPLES[i][0], R_F_SINUSOID_SAMPLES[i][1],
                                      V_F_SINUSOID_SAMPLES[i][0], V_F_SINUSOID_SAMPLES[i][1]);

        GuidanceLaw_Cmd();
        ControlSystemSpy_GetCmd(&a_cmd);

        DOUBLES_EQUAL(A_CMD_SINUSOID_SAMPLES[i][0], a_cmd.cmd_x, ACMD_TOL);
        DOUBLES_EQUAL(A_CMD_SINUSOID_SAMPLES[i][1], a_cmd.cmd_y, ACMD_TOL);
    }
}