/*
 * task_monitor.c
 *
 *  Created on: 16 may 2026
 *      Author: eduno
 */

#include "task_monitor.h"
#include "app_config.h"
#include "task_tcpserver.h"
#include "task_guidancelaw.h"
#include "cmsis_os.h"
#include "FreeRTOS.h"
#include "task.h"
#include <stdio.h>
#include "stm32f7xx.h"

void configureTimerForRunTimeStats(void)
{
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    DWT->LAR     = 0xC5ACCE55;
    DWT->CYCCNT  = 0U;
    DWT->CTRL   |= DWT_CTRL_CYCCNTENA_Msk;
}

unsigned long getRunTimeCounterValue(void)
{
    return (unsigned long)(DWT->CYCCNT >> 4U);
}

static uint32_t cycles_to_us(uint32_t cycles)
{
    return cycles / (SystemCoreClock / 1000000U);
}

static void monitor_thread(void const *argument);

osThreadDef(monitorThread, monitor_thread, PRIO_MONITOR, 0, STACK_MONITOR);

void task_monitor_start(void)
{
    osThreadId id = osThreadCreate(osThread(monitorThread), NULL);
    configASSERT(id != NULL);
}

static void monitor_thread(void const *argument)
{
    (void)argument;

    for (;;)
    {
        osDelay(MONITOR_PERIOD_MS);
        printf("[MON] === Stack High Water Marks ===\r\n");
        printf("[MON] TCP server : %u words\r\n",
               (unsigned)uxTaskGetStackHighWaterMark(task_tcpserver_get_handle()));
        printf("[MON] Guidance   : %u words\r\n",
               (unsigned)uxTaskGetStackHighWaterMark(task_guidancelaw_get_handle()));
        printf("[MON] Monitor    : %u words\r\n",
               (unsigned)uxTaskGetStackHighWaterMark(NULL));
        printf("[MON] Heap min   : %u bytes\r\n",
               (unsigned)xPortGetMinimumEverFreeHeapSize());
        printf("[MON] ===================================\r\n");
        guidancelaw_stats_t gl;
        task_guidancelaw_get_stats(&gl);
        if (gl.count > 0U) {
            printf("[MON] -------------------------------------------\r\n");
            printf("[MON] GuidanceLaw_Cmd timing\r\n");
            printf("[MON]   Last : %8lu cyc  (%6lu us)\r\n",
                   (unsigned long)gl.last_cycles,
                   (unsigned long)cycles_to_us(gl.last_cycles));
            printf("[MON]   Min  : %8lu cyc  (%6lu us)\r\n",
                   (unsigned long)gl.min_cycles,
                   (unsigned long)cycles_to_us(gl.min_cycles));
            printf("[MON]   Max  : %8lu cyc  (%6lu us)\r\n",
                   (unsigned long)gl.max_cycles,
                   (unsigned long)cycles_to_us(gl.max_cycles));
            printf("[MON]   Avg  : %8lu cyc  (%6lu us)\r\n",
                   (unsigned long)gl.avg_cycles,
                   (unsigned long)cycles_to_us(gl.avg_cycles));
            printf("[MON]   N    : %lu samples\r\n",
                   (unsigned long)gl.count);
        }
    }
}


