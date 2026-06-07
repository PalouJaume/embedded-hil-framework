/*
 * task_guidancelaw.c
 *
 *  Created on: 16 may 2026
 *      Author: eduno
 */
#include "task_guidancelaw.h"
#include "app_ipc.h"
#include "app_config.h"
#include "cmsis_os.h"
#include "FreeRTOS.h"

#include "ControlSystem.h"
#include "Planner.h"
#include "NavigationSystem.h"
#include "GuidanceLaw.h"

#include "stm32f7xx.h"
#include "limits.h"
#include "string.h"

static osThreadId guidancelaw_handle;

static POS_2D recv_p;
static STATE_2D recv_state;
static CMD_2D send_cmd;

typedef struct {
    uint32_t last_cycles;
    uint32_t min_cycles;
    uint32_t max_cycles;
    uint64_t sum_cycles;   /* 64 bits: evita wrap del acumulador */
    uint32_t count;
} guidancelaw_stats_internal_t;

static guidancelaw_stats_internal_t g_stats = {
    .min_cycles = UINT32_MAX,
};

void task_guidancelaw_get_stats(guidancelaw_stats_t *out)
{
    taskENTER_CRITICAL();
    out->last_cycles = g_stats.last_cycles;
    out->min_cycles  = (g_stats.count == 0U) ? 0U : g_stats.min_cycles;
    out->max_cycles  = g_stats.max_cycles;
    out->avg_cycles  = (g_stats.count > 0U)
                     ? (uint32_t)(g_stats.sum_cycles / g_stats.count)
                     : 0U;
    out->count       = g_stats.count;
    taskEXIT_CRITICAL();
}

void task_guidancelaw_reset_stats(void)
{
    taskENTER_CRITICAL();
    memset(&g_stats, 0, sizeof(g_stats));
    g_stats.min_cycles = UINT32_MAX;
    taskEXIT_CRITICAL();
}

void ControlSystem_SendCmd(CMD_2D a)
{
	send_cmd = a;
}

void NavigationSystem_GetState(STATE_2D *state)
{
	*state = recv_state;
}

void Planner_GetPoint(POS_2D *p)
{
	*p = recv_p;
}

static void guidancelaw_thread(void const *argument);

osThreadDef(guidancelawThread, guidancelaw_thread, PRIO_GUIDANCELAW, 0, STACK_GUIDANCELAW);

void task_guidancelaw_start(void)
{
	guidancelaw_handle = osThreadCreate(osThread(guidancelawThread), NULL);
	configASSERT(guidancelaw_handle != NULL);
}

osThreadId task_guidancelaw_get_handle(void)
{
    return guidancelaw_handle;
}

static void guidancelaw_thread(void const *argument)
{
    for (;;)
    {
        /* 1. Recibir entrada del server */
        osEvent evt = osMailGet(mailGuidanceLaw, osWaitForever);
        if (evt.status != osEventMail) {
            continue;
        }
        PACK_48B *in = (PACK_48B *)evt.value.p;

        /* 2. Procesar  */
        recv_p.x       = in->rp_x;
        recv_p.y       = in->rp_y;
        recv_state.r_x = in->rm_x;
        recv_state.r_y = in->rm_y;
        recv_state.v_x = in->vm_x;
        recv_state.v_y = in->vm_y;

        /* 3. Liberar el mail */
        osMailFree(mailGuidanceLaw, in);

        /* 4. Operar */
        uint32_t t0 = DWT->CYCCNT;
        GuidanceLaw_Cmd();
        uint32_t dt = DWT->CYCCNT - t0;

        taskENTER_CRITICAL();
        g_stats.last_cycles = dt;
        if (dt < g_stats.min_cycles) g_stats.min_cycles = dt;
        if (dt > g_stats.max_cycles) g_stats.max_cycles = dt;
        g_stats.sum_cycles += dt;
        g_stats.count++;
        taskEXIT_CRITICAL();

        /* 5. Responder al server */
        PACK_16B *out = osMailAlloc(mailServer, osWaitForever);
        if (out != NULL) {
            out->cmd_x = send_cmd.cmd_x;
            out->cmd_y = send_cmd.cmd_y;
            osMailPut(mailServer, out);
        }
    }
}


































