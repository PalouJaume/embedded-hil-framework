/*
 * app.c
 *
 *  Created on: 15 may 2026
 *      Author: eduno
 */
#include "app.h"
#include "retarget.h"
#include "app_ipc.h"
#include "task_tcpserver.h"
#include "task_guidancelaw.h"
#include "task_monitor.h"

void app_init(void)
{
	app_ipc_init();
	retarget_init();
	task_guidancelaw_start();
	task_tcpserver_start();
	task_monitor_start();
}

