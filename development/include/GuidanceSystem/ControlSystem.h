#ifndef D_CONTROL_SYSTEM_H
#define D_CONTROL_SYSTEM_H

typedef struct CMD_2D
{
    double cmd_x;
    double cmd_y;
} CMD_2D;

void ControlSystem_Create(void);
void ControlSystem_Destroy(void);
void ControlSystem_SendCmd(CMD_2D a);

#endif /* D_CONTROL_SYSTEM_H */