#include "unity_fixture.h"

static void RunAllTests(void)
{
    RUN_TEST_GROUP(FakeNavigationSystem);
    RUN_TEST_GROUP(FakePlanner);
    RUN_TEST_GROUP(ControlSystemSpy);
    RUN_TEST_GROUP(GuidanceLaw);
}

int main(int argc, const char *argv[])
{
    return UnityMain(argc, argv, RunAllTests);
}