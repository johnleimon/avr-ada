//
// avr-thread-mutex-basic
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread-mutex-basic.c,v 1.3 2008-09-04 01:10:01 dean Exp $
// Dean Ferreyra

// Simplified mutexes.

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

void avr_thread_mutex_basic_gain(volatile avr_thread_mutex_basic* mutex)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (! mutex->locked) {
	mutex->locked = 1;
        SREG = sreg;
        avr_thread_enable();
    } else {
	avr_thread_active->waiting_for = mutex;
	avr_thread_active->state = ats_wait;
        SREG = sreg;
	avr_thread_switch();
    }
}

uint8_t avr_thread_mutex_basic_test_and_gain(volatile avr_thread_mutex_basic*
                                             mutex)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (! mutex->locked) {
	mutex->locked = 1;
        SREG = sreg;
	avr_thread_enable();
	return 1;
    } else {
        SREG = sreg;
	avr_thread_enable();
	return 0;
    }
}

void avr_thread_mutex_basic_release(volatile avr_thread_mutex_basic* mutex)
{
    avr_thread_disable();

    uint8_t sreg = SREG;
    cli();

    if (mutex->locked) {
	// Go through task list and find someone that's waiting on this.
	avr_thread_context* task =
	    (avr_thread_context*)avr_thread_active->next;
	while (task != avr_thread_active) {
	    if (task->waiting_for == mutex) {
		task->waiting_for = 0;
		// Awaken thread.
		task->state &= ~(ats_wait | ats_tick);
                SREG = sreg;
		avr_thread_enable();
		return;
	    }
	    task = (avr_thread_context*)task->next;
	}
	// Unlock mutex.
	mutex->locked = 0;
    }
    SREG = sreg;
    avr_thread_enable();
}
