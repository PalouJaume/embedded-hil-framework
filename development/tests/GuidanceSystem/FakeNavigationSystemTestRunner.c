#include "unity_fixture.h"

TEST_GROUP_RUNNER(FakeNavigationSystem)
{
    RUN_TEST_CASE(FakeNavigationSystem, StartHere);
    RUN_TEST_CASE(FakeNavigationSystem, Create);
    RUN_TEST_CASE(FakeNavigationSystem, Set);
}