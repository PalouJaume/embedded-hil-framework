/*
 * task_tcpserver.c
 *
 *  Created on: 15 may 2026
 *      Author: eduno
 */
#include "task_tcpserver.h"
#include "app_ipc.h"
#include "app_config.h"
#include "cmsis_os.h"
#include "FreeRTOS.h"

#include "lwip/api.h"
#include "string.h"

static osThreadId tcpserver_handle;

static void tcpserver_thread(void const *argument);

osThreadDef(tcpserverThread, tcpserver_thread, PRIO_TCPSERVER, 0, STACK_TCPSERVER);

void task_tcpserver_start(void)
{
	tcpserver_handle = osThreadCreate(osThread(tcpserverThread), NULL);
	configASSERT(tcpserver_handle != NULL);
}

osThreadId task_tcpserver_get_handle(void)
{
    return tcpserver_handle;
}

static void tcpserver_thread(void const *argument)
{
	struct netconn *conn, *newconn;
	struct netbuf *buf;
	char msg[100];
	char smsg[200];

	err_t err, accept_err;

	conn = netconn_new(NETCONN_TCP);

	if (conn != NULL)
	{
		err = netconn_bind(conn, IP_ADDR_ANY, 7);

		if (err == ERR_OK)
		{
			netconn_listen(conn);

			while (1)
			{
				accept_err = netconn_accept(conn, &newconn);

				if (accept_err == ERR_OK)
				{
					while (netconn_recv(newconn, &buf) == ERR_OK)
					{
						do {
							strncpy(msg, buf->p->payload, buf->p->len);

							if (buf->p->len == 48)
							{
			                    /* a) Encolar estado a guidance */
			                    PACK_48B *out = osMailAlloc(mailGuidanceLaw, osWaitForever);
			                    if (out != NULL) {
			                        memcpy(out, buf->p->payload, sizeof(PACK_48B));
			                        osMailPut(mailGuidanceLaw, out);
			                    }

			                    /* b) Esperar comando de respuesta */
			                    osEvent evt = osMailGet(mailServer, osWaitForever);
			                    if (evt.status == osEventMail) {
			                        PACK_16B *in = (PACK_16B *)evt.value.p;
			                        netconn_write(newconn, in, sizeof(PACK_16B), NETCONN_COPY);
			                        osMailFree(mailServer, in);
			                    }
							} else
							{
								int len = sprintf(smsg, "\"%s\" was sent by the Server\n", msg);

								netconn_write(newconn, smsg, len, NETCONN_COPY);
								memset(msg, '\0', 100);
							}
						} while (netbuf_next(buf) > 0);

						netbuf_delete(buf);
					}

					netconn_close(newconn);
					netconn_delete(newconn);
				}
			}
		} else
		{
			netconn_delete(conn);
		}
	}
}
