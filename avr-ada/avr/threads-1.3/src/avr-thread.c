//
// avr-thread
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread.c,v 1.4 2008-11-11 19:05:43 dean Exp $
// Dean Ferreyra

// Threads for AVR.

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
#include <compat/deprecated.h>
#include <stdlib.h>
#include <string.h>
#include "avr-thread-asm.h"
#include "avr-thread.h"
#include "avr-thread-def.h"


avr_thread_context avr_thread_idle_context;
avr_thread_context avr_thread_main_context;

volatile uint8_t avr_thread_disabled;
avr_thread_context* avr_thread_active;

uint8_t avr_thread_idle_stack[128] __attribute__((weak));
void avr_thread_idle(void)
{
    // If we're idling, no need to try to task switch
    // because there's no one to task switch to.
    // Let the isr do the switch.
    for (;;)
	;
}

void avr_thread_init(void)
{
    // Initialize idle context.
    avr_thread_start_at(&avr_thread_idle_context,
			avr_thread_idle,
			avr_thread_idle_stack,
			sizeof(avr_thread_idle_stack));
    avr_thread_idle_context.next_waiting = &avr_thread_idle_context;
    avr_thread_idle_context.prev_waiting = &avr_thread_idle_context;

    // Initialize main() context.
    avr_thread_active = &avr_thread_main_context;
    avr_thread_active->state = ats_normal;
    avr_thread_active->stack_ptr = 0;
#if DEBUG_STACK_USAGE
    avr_thread_active->min_stack_ptr =
	avr_thread_active->stack_end = (uint8_t*)(RAMEND + 1);
#endif
    // Cast away volatile.
    avr_thread_active->next = (avr_thread_context*)avr_thread_active;
}

void avr_thread_start(avr_thread_context* context,
		      void (*fn)(void),
		      uint8_t* stack,
		      uint16_t stack_size)
{
    avr_thread_start_at(context, fn, stack, stack_size);
    uint8_t sreg = SREG;
    cli();
    context->next = avr_thread_active->next;
    avr_thread_active->next = context;
    SREG = sreg;
}

void avr_thread_start_at(avr_thread_context* context,
			 void (*fn)(void),
			 uint8_t* stack,
			 uint16_t stack_size)
{
    context->state = ats_normal;
    context->stack_ptr = stack + stack_size
	- RETURN_SIZE - REGISTERS_SIZE - SREG_SIZE - 1;
#if DEBUG_STACK_USAGE
    context->min_stack_ptr = context->stack_end = stack + stack_size;
#endif

    // Prepare the new stack.

#if DEBUG_STACK_USAGE
    memset(stack, DEBUG_STACK_VALUE, stack_size);
#endif

    // Place function address as return address.
    *(stack + stack_size - RETURN_SIZE) = (uint16_t)fn >> 8;
    *(stack + stack_size - RETURN_SIZE + 1) = (uint8_t)(uint16_t)fn;

    // Zero out all the registers that will be popped on first switch.
    memset(stack + stack_size - RETURN_SIZE - REGISTERS_SIZE,
	   0,
	   REGISTERS_SIZE);

    // Setup frame pointer in Y.
    *(stack + stack_size - RETURN_SIZE - 4) =
	(uint16_t)(stack + stack_size - 1);
    *(stack + stack_size - RETURN_SIZE - 3) =
	(uint16_t)(stack + stack_size - 1) >> 8;

    // Setup SREG with global interrupts enabled.
    *(stack + stack_size - RETURN_SIZE - REGISTERS_SIZE - SREG_SIZE) =
	inp(SREG) | _BV(SREG_I);
}

void avr_thread_tick_only(void)
{
    volatile avr_thread_context* task = avr_thread_active;
    do {
	task = task->next;
	if ((task->state & ats_tick) && ! --task->timeout)
	    task->state &= ~(ats_wait | ats_tick);
    } while (task->next != avr_thread_active->next);
}

// Call with interrupts disabled?
volatile avr_thread_context* avr_thread_find_next(uint8_t in_isr)
{
    volatile avr_thread_context* task = avr_thread_active;
    volatile avr_thread_context* to_run = 0;

    do {
        task = task->next;
        if (in_isr) {
            // Do tick
            if ((task->state & ats_tick) && ! --task->timeout)
                task->state &= ~(ats_wait | ats_tick);
        }
        if (! (task->state & ats_wait) && ! to_run) {
            to_run = task;
            if (! in_isr)
                break;
        }
    } while (task->next != avr_thread_active->next);
    if (to_run)
        return to_run;
    else {
        // Set up idle and return it.
        avr_thread_idle_context.next = avr_thread_active->next;
        return &avr_thread_idle_context;
    }
}
