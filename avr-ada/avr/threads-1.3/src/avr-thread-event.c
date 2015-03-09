//
// avr-thread-event
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread-event.c,v 1.3 2008-09-04 01:10:01 dean Exp $
// Dean Ferreyra

// Events.

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

void avr_thread_event_set_wake_one(volatile avr_thread_event* event)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    event->state = 1;

    // Go through wait list and find someone that's waiting on this.
    avr_thread_context* task =
	(avr_thread_context*)avr_thread_idle_context.next_waiting;
    while (task != &avr_thread_idle_context) {
	if (task->waiting_for == event) {
	    // Clear if clear reqeusted.
	    if (task->state & ats_clear)
		event->state = 0;
	    // Show success.
	    task->waiting_for = 0;
	    // Awaken thread.
	    task->state &= ~(ats_wait | ats_tick);
	    break;
	}
	task = (avr_thread_context*)task->next_waiting;
    }
    SREG = sreg;
    avr_thread_enable();
}

void avr_thread_event_set_wake_all(volatile avr_thread_event* event)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    event->state = 1;

    // Go through wait list and find all threads waiting on this.
    avr_thread_context* task =
	(avr_thread_context*)avr_thread_idle_context.next_waiting;
    while (task != &avr_thread_idle_context) {
	if (task->waiting_for == event) {
	    // Clear if clear reqeusted.
	    if (task->state & ats_clear)
		event->state = 0;
	    // Show success.
	    task->waiting_for = 0;
	    // Awaken thread.
	    task->state &= ~(ats_wait | ats_tick);
	}
	task = (avr_thread_context*)task->next_waiting;
    }
    SREG = sreg;
    avr_thread_enable();
}

void avr_thread_event_clear(volatile avr_thread_event* event)
{
    avr_thread_disable();
    uint8_t sreg = SREG;
    cli();
    event->state = 0;
    SREG = sreg;
    avr_thread_enable();
}

uint8_t avr_thread_event_wait(volatile avr_thread_event* event,
                              uint16_t ticks)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (event->state) {
        SREG = sreg;
	avr_thread_enable();
	return 1;
    } else {
	// Wait for event.
	avr_thread_active->waiting_for = event;

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

	// Take ourselves out of the wait queue.
	avr_thread_disable();

        sreg = SREG;
        cli();

	avr_thread_active->prev_waiting->next_waiting =
	    avr_thread_active->next_waiting;
	avr_thread_active->next_waiting->prev_waiting =
	    avr_thread_active->prev_waiting;

        SREG = sreg;
	avr_thread_enable();

	// At this point, have we gained ownership?
	return avr_thread_active->waiting_for == 0;
    }
}

uint8_t avr_thread_event_wait_and_clear(volatile avr_thread_event* event,
					uint16_t ticks)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (event->state) {
	event->state = 0;
        SREG = sreg;
	avr_thread_enable();
	return 1;
    } else {
	// Wait for event.
	avr_thread_active->waiting_for = event;

	// Put task in waiting queue.
	avr_thread_active->next_waiting = &avr_thread_idle_context;
	avr_thread_active->prev_waiting = avr_thread_idle_context.prev_waiting;
	avr_thread_idle_context.prev_waiting->next_waiting = avr_thread_active;
	avr_thread_idle_context.prev_waiting = avr_thread_active;

	if (! ticks)
	    avr_thread_active->state = ats_wait | ats_clear;
	else {
	    avr_thread_active->timeout = ticks;
	    avr_thread_active->state = ats_wait | ats_clear | ats_tick;
	}
        SREG = sreg;
	avr_thread_switch();

	// Take ourselves out of the wait queue.
	avr_thread_disable();
        sreg = SREG;
        cli();
	avr_thread_active->prev_waiting->next_waiting =
	    avr_thread_active->next_waiting;
	avr_thread_active->next_waiting->prev_waiting =
	    avr_thread_active->prev_waiting;
        SREG = sreg;
	avr_thread_enable();

	// At this point, have we gained ownership?
	return avr_thread_active->waiting_for == 0;
    }
}
