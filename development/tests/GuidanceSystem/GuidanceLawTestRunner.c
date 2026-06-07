#include "unity_fixture.h"

TEST_GROUP_RUNNER(GuidanceLaw)
{
    RUN_TEST_CASE(GuidanceLaw, StartHere);
    RUN_TEST_CASE(GuidanceLaw, OnTrackNullCmd);
    RUN_TEST_CASE(GuidanceLaw, ZeroVelocityNullCmd);
    RUN_TEST_CASE(GuidanceLaw, AlignNullCmd);
    RUN_TEST_CASE(GuidanceLaw, Sinusoid_T60);
    RUN_TEST_CASE(GuidanceLaw, Line_T30);
    RUN_TEST_CASE(GuidanceLaw, Circle_T0);
    RUN_TEST_CASE(GuidanceLaw, Circle_RandomSamples);
    RUN_TEST_CASE(GuidanceLaw, Line_RandomSamples);
    RUN_TEST_CASE(GuidanceLaw, Sinusoid_RandomSamples);
}