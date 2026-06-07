/*
 * app_hooks.c
 *
 *  Created on: 16 may 2026
 *      Author: eduno
 */
#include "FreeRTOS.h"
#include "task.h"
#include "app_hooks.h"

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    (void)xTask;
    (void)pcTaskName;

    for (;;) {}
}
