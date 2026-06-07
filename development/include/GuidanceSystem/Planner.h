#ifndef D_PLANNER_H
#define D_PLANNER_H

typedef struct POS_2D
{
    double x;
    double y;
} POS_2D;

void Planner_Create(void);
void Planner_Destroy(void);
void Planner_GetPoint(POS_2D *pos);

#endif /* D_PLANNER_H */