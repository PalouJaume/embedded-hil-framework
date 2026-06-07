#include "unity_fixture.h"
#include "FakePlanner.h"

TEST_GROUP(FakePlanner);

static void checkPoint(double rx, double ry, POS_2D point)
{
    DOUBLES_EQUAL(rx, point.x, 0);
    DOUBLES_EQUAL(ry, point.y, 0);
}

TEST_SETUP(FakePlanner)
{
    Planner_Create();
}

TEST_TEAR_DOWN(FakePlanner)
{
}

TEST(FakePlanner, StartHere)
{
    // TEST_FAIL_MESSAGE("Start Here");
}

TEST(FakePlanner, Create)
{
    POS_2D point;

    Planner_GetPoint(&point);

    checkPoint(0.0, 0.0, point);
}

TEST(FakePlanner, Set)
{
    FakePlanner_SetPoint(10.0, 5.0);

    POS_2D point;

    Planner_GetPoint(&point);

    checkPoint(10.0, 5.0, point);
}