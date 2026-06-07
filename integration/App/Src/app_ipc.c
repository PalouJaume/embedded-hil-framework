/*
 * app_ipc.c
 *
 *  Created on: 15 may 2026
 *      Author: eduno
 */
#include "app_ipc.h"
#include "app_config.h"
#include "FreeRTOS.h"

osMailQDef(mailServer, QUEUE_SERVER_LEN, PACK_16B);
osMailQId mailServer;

osMailQDef(mailGuidanceLaw, QUEUE_GUIDANCELAW_LEN, PACK_48B);
osMailQId mailGuidanceLaw;

void app_ipc_init(void)
{
    mailServer = osMailCreate(osMailQ(mailServer), NULL);
    configASSERT(mailServer    != NULL);
    mailGuidanceLaw = osMailCreate(osMailQ(mailGuidanceLaw), NULL);
    configASSERT(mailGuidanceLaw    != NULL);
}

