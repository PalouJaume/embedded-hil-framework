/*
 * task_monitor.h
 *
 *  Created on: 16 may 2026
 *      Author: eduno
 */

#ifndef INC_TASK_MONITOR_H_
#define INC_TASK_MONITOR_H_

void task_monitor_start(void);
void          configureTimerForRunTimeStats(void);
unsigned long getRunTimeCounterValue(void);

#endif /* INC_TASK_MONITOR_H_ */
