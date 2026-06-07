#include "unity_fixture.h"

TEST_GROUP_RUNNER(FakePlanner)
{
    RUN_TEST_CASE(FakePlanner, StartHere);
    RUN_TEST_CASE(FakePlanner, Create);
    RUN_TEST_CASE(FakePlanner, Set);
}