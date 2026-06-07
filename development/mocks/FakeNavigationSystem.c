#include "FakeNavigationSystem.h"

static double nav_rx;
static double nav_ry;
static double nav_vx;
static double nav_vy;

void NavigationSystem_GetState(STATE_2D *state)
{
    state->r_x = nav_rx;
    state->r_y = nav_ry;
    state->v_x = nav_vx;
    state->v_y = nav_vy;
}

void NavigationSystem_Create(void)
{
}

void NavigationSystem_Destroy(void)
{
}

void FakeNavigationSystem_SetState(double r_x, double r_y,
                                   double v_x, double v_y)
{
    nav_rx = r_x;
    nav_ry = r_y;
    nav_vx = v_x;
    nav_vy = v_y;
}