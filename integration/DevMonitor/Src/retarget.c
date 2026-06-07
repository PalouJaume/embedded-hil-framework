/*
 * retarget.c
 *
 *  Created on: 16 may 2026
 *      Author: eduno
 */
#include "retarget.h"
#include "stm32f7xx_hal.h"
#include "cmsis_os.h"
#include "task.h"
#include <stdio.h>

extern UART_HandleTypeDef huart3;

static osMutexId print_mutex;

void retarget_init(void)
{
    setvbuf(stdout, NULL, _IONBF, 0);   /* sin buffering: flush inmediato */
    osMutexDef(print_mutex);
    print_mutex = osMutexCreate(osMutex(print_mutex));

    printf("[BOOT] Sistema iniciado. UART OK\r\n");
}

int _write(int file, char *ptr, int len)
{
    (void)file;

    /* Antes de que arranque el scheduler no existe el mutex todavía */
    if (xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED)
        osMutexWait(print_mutex, osWaitForever);

    HAL_UART_Transmit(&huart3, (uint8_t *)ptr, (uint16_t)len, HAL_MAX_DELAY);

    if (xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED)
        osMutexRelease(print_mutex);

    return len;
}

