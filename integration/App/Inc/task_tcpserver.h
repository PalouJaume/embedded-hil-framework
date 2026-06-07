/*
 * task_tcpserver.h
 *
 *  Created on: 15 may 2026
 *      Author: eduno
 */

#ifndef INC_TASK_TCPSERVER_H_
#define INC_TASK_TCPSERVER_H_

#include "cmsis_os.h"

void task_tcpserver_start(void);
osThreadId task_tcpserver_get_handle(void);

#endif /* INC_TASK_TCPSERVER_H_ */
