//
// avr-thread-stop
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread-stop.c,v 1.3 2008-09-04 01:10:01 dean Exp $
// Dean Ferreyra

// Stopping threads.

/*
This file is part of AVR-THREADS.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; see the file COPYING.LIB.  If not,
write to the Free Software Foundation, Inc., 59 Temple Place, Suite
330, Boston, MA 02111-1307  USA

Contact information:

Dean Ferreyra
12902 Malena Drive
Santa Ana, CA 92705-1102  USA

dean@octw.com
*/

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include <string.h>
#include "avr-thread-asm.h"
#include "avr-thread.h"
#include "avr-thread-def.h"

void avr_thread_stop(void)
{
    avr_thread_disable();
    uint8_t sreg = SREG;
    cli();
    volatile avr_thread_context* prev_task =
        avr_thread_active;
    volatile avr_thread_context* task = prev_task->next;
    for (;;) {
	if (task == avr_thread_active) {
	    // Take self out of queue.
	    prev_task->next = task->next;
	    break;
	}
	prev_task = task;
	task = task->next;
    }
    SREG = sreg;
    avr_thread_switch();
}

