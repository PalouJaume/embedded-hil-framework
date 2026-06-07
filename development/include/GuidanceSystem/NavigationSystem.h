#ifndef D_NAVIGATION_SYSTEM_H
#define D_NAVIGATION_SYSTEM_H

typedef struct STATE_2D
{
    double r_x;
    double r_y;
    double v_x;
    double v_y;
} STATE_2D;

void NavigationSystem_Create(void);
void NavigationSsytem_Destroy(void);
void NavigationSystem_GetState(STATE_2D *state);

#endif /* D_NAVIGATION_SYSTEM_H */