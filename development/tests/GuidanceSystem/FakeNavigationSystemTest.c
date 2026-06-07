#include "unity_fixture.h"
#include "FakeNavigationSystem.h"

TEST_GROUP(FakeNavigationSystem);

static void check_state(double rx, double ry, double vx, double vy, STATE_2D state)
{
    DOUBLES_EQUAL(rx, state.r_x, 0);
    DOUBLES_EQUAL(ry, state.r_y, 0);
    DOUBLES_EQUAL(vx, state.v_x, 0);
    DOUBLES_EQUAL(vy, state.v_y, 0);
}

TEST_SETUP(FakeNavigationSystem)
{
    NavigationSystem_Create();
}

TEST_TEAR_DOWN(FakeNavigationSystem)
{
}

TEST(FakeNavigationSystem, StartHere)
{
    // TEST_FAIL_MESSAGE("Start Here");
}

TEST(FakeNavigationSystem, Create)
{
    STATE_2D state;

    NavigationSystem_GetState(&state);

    check_state(0.0, 0.0, 0.0, 0.0, state);
}

TEST(FakeNavigationSystem, Set)
{
    STATE_2D state;

    FakeNavigationSystem_SetState(1.0, 2.3, 6.8, 10.111);

    NavigationSystem_GetState(&state);

    check_state(1.0, 2.3, 6.8, 10.111, state);
}