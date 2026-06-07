/*
 * task_guidancelaw.h
 *
 *  Created on: 16 may 2026
 *      Author: eduno
 */

#ifndef INC_TASK_GUIDANCELAW_H_
#define INC_TASK_GUIDANCELAW_H_

#include "stdint.h"
#include "cmsis_os.h"

typedef struct {
    uint32_t last_cycles;
    uint32_t min_cycles;
    uint32_t max_cycles;
    uint32_t avg_cycles;
    uint32_t count;
} guidancelaw_stats_t;

void task_guidancelaw_start(void);
osThreadId task_guidancelaw_get_handle(void);

void task_guidancelaw_get_stats(guidancelaw_stats_t *out);
void task_guidancelaw_reset_stats(void);

#endif /* INC_TASK_GUIDANCELAW_H_ */
