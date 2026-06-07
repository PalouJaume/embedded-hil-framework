/*
 * app_ipc.h
 *
 *  Created on: 15 may 2026
 *      Author: eduno
 */

#ifndef INC_APP_IPC_H_
#define INC_APP_IPC_H_

#include "cmsis_os.h"
#include "stdint.h"

typedef struct PACK_48B
{
    double rm_x;
    double rm_y;
    double vm_x;
    double vm_y;
    double rp_x;
    double rp_y;
} PACK_48B;

typedef struct PACK_16B
{
	double cmd_x;
	double cmd_y;
} PACK_16B;

extern osMailQId     mailServer;
extern osMailQId     mailGuidanceLaw;

void app_ipc_init(void);

#endif /* INC_APP_IPC_H_ */
