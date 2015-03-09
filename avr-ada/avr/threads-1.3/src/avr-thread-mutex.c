//
// avr-thread-mutex
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread-mutex.c,v 1.3 2008-09-04 01:10:01 dean Exp $
// Dean Ferreyra

// Mutexes.

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

uint8_t avr_thread_mutex_gain(volatile avr_thread_mutex* mutex,
                              uint16_t ticks)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (! mutex->lock_count) {
	// Take ownership.
	mutex->owner = avr_thread_active;
	mutex->lock_count = 1;
        SREG = sreg;
	avr_thread_enable();
	return 1;
    } else if (mutex->owner == avr_thread_active) {
	// Already owned by self.
	++mutex->lock_count;
        SREG = sreg;
	avr_thread_enable();
	return 1;
    } else {
	// Wait for mutex.
	avr_thread_active->waiting_for = mutex;

	// Put task in waiting queue.
	avr_thread_active->next_waiting = &avr_thread_idle_context;
	avr_thread_active->prev_waiting = avr_thread_idle_context.prev_waiting;
	avr_thread_idle_context.prev_waiting->next_waiting = avr_thread_active;
	avr_thread_idle_context.prev_waiting = avr_thread_active;

	if (! ticks)
	    avr_thread_active->state = ats_wait;
	else {
	    avr_thread_active->timeout = ticks;
	    avr_thread_active->state = ats_wait | ats_tick;
	}
        SREG = sreg;
	avr_thread_switch();
	// At this point, have we gained ownership?
	return avr_thread_active->waiting_for == 0;
    }
}

void avr_thread_mutex_release(volatile avr_thread_mutex* mutex)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (mutex->owner != avr_thread_active) {
        SREG = sreg;
	avr_thread_enable();
	return;
    } else {
	if (--mutex->lock_count) {
            SREG = sreg;
	    avr_thread_enable();
	    return;
	} else {
	    // Go through wait list and find someone that's waiting on this.
	    avr_thread_context* task =
		(avr_thread_context*)avr_thread_idle_context.next_waiting;
	    while (task != &avr_thread_idle_context) {
		if (task->waiting_for == mutex) {
		    // Give task ownership.
		    mutex->owner = task;
		    mutex->lock_count = 1;
		    // Show success.
		    task->waiting_for = 0;
		    // Awaken thread.
		    task->state &= ~(ats_wait | ats_tick);
                    // Take thread out of wait queue.
                    task->prev_waiting->next_waiting =
                        task->next_waiting;
                    task->next_waiting->prev_waiting =
                        task->prev_waiting;
                    SREG = sreg;
		    avr_thread_enable();
		    return;
		}
		task = (avr_thread_context*)task->next_waiting;
	    }
            SREG = sreg;
	    // Give up ownership.
	    mutex->owner = 0;
	    avr_thread_enable();
	    return;
	}
    }
}
