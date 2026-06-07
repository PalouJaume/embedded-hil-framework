#include "FakePlanner.h"

static POS_2D fake_track;

void Planner_Create(void)
{
    fake_track.x = 0;
    fake_track.y = 0;
}

void Planner_GetPoint(POS_2D *point)
{
    point->x = fake_track.x;
    point->y = fake_track.y;
}

void FakePlanner_SetPoint(double rx, double ry)
{
    fake_track.x = rx;
    fake_track.y = ry;
}