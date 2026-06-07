/*
 * app_config.h
 *
 *  Created on: 15 may 2026
 *      Author: eduno
 */

#ifndef INC_APP_CONFIG_H_
#define INC_APP_CONFIG_H_

#include "cmsis_os.h"
#include "lwip/api.h"

#define PRIO_TCPSERVER    osPriorityNormal
#define PRIO_GUIDANCELAW  osPriorityNormal
#define PRIO_MONITOR      osPriorityLow

#define STACK_TCPSERVER   DEFAULT_THREAD_STACKSIZE
#define STACK_GUIDANCELAW 512U
#define STACK_MONITOR     256U

#define QUEUE_GUIDANCELAW_LEN    1U
#define QUEUE_SERVER_LEN         1U

#define MONITOR_PERIOD_MS   10000U

#endif /* INC_APP_CONFIG_H_ */
