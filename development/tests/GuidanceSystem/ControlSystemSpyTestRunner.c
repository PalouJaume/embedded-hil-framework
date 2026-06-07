#include "unity_fixture.h"

TEST_GROUP_RUNNER(ControlSystemSpy)
{
    RUN_TEST_CASE(ControlSystemSpy, StartHere);
    RUN_TEST_CASE(ControlSystemSpy, CreateUnknownStatus);
    RUN_TEST_CASE(ControlSystemSpy, SetStatus);
    RUN_TEST_CASE(ControlSystemSpy, SetCmdGetCmd);
}