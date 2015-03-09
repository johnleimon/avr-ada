
/*
 * avr-thread-switch
 *
 * Forced task switch.
 *
 * Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
 *
 * $Id: avr-thread-switch.S,v 1.4 2008-11-11 19:05:43 dean Exp $
 * Dean Ferreyra
 */

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
#include "avr-thread-asm.h"

	tmp_reg = 0
	zero_reg = 1

	.text


/* Enter this function with switcher disabled. */

.global	avr_thread_switch
	.type	avr_thread_switch,@function
	
avr_thread_switch:

	/* Save all registers. */
	PUSH_ALL

	/* Save SREG. */
	in XL,_SFR_IO_ADDR(SREG)
	sbr XL,_BV(SREG_I)
	push XL

        /* Save current stack pointer back to current context. */
	lds YL,avr_thread_active
	lds YH,(avr_thread_active)+1
	in XL,_SFR_IO_ADDR(SPL)
#ifdef SPH
	in XH,_SFR_IO_ADDR(SPH)
#endif
        
	std Y+CONTEXT_STACK_PTR,XL
	std Y+CONTEXT_STACK_PTR+1,XH

#if DEBUG_STACK_USAGE
	/* Add the pushes and call to avr_thread_find_next. */
	sbiw XL,6
	/* Disable interrupts because task switcher still updates */
	/* min_stack_ptr even while switcher is disabled. */
	in tmp_reg,_SFR_IO_ADDR(SREG)
	cli
	/* Add the call to avr_thread_find_next and its 4 pushes. */
	ldd r24,Y+CONTEXT_MIN_STACK_PTR
	ldd r25,Y+CONTEXT_MIN_STACK_PTR+1
	cp XL,r24
	cpc XH,r25
	brsh .stack_greater_or_equal_stack_min
	std Y+CONTEXT_MIN_STACK_PTR,XL
	std Y+CONTEXT_MIN_STACK_PTR+1,XH
.stack_greater_or_equal_stack_min:
	out _SFR_IO_ADDR(SREG),tmp_reg
#endif

	/* Find next thread to run.    */
	/* Not in isr. */
	/* Context address returned in r25:r24 */
	eor r24,r24
	eor zero_reg,zero_reg
	in tmp_reg,_SFR_IO_ADDR(SREG)
        push tmp_reg
	cli
#if __AVR_ARCH__ == 3 || __AVR_ARCH__ == 5
	call avr_thread_find_next
#else
	rcall avr_thread_find_next
#endif
        pop tmp_reg
	out _SFR_IO_ADDR(SREG),tmp_reg
	mov YL,r24
	mov YH,r25
	/* Disable interrupts because task switcher still traverses */
	/* task list to update timeouts even while switcher is disabled. */
	ldd XL,Y+CONTEXT_STACK_PTR
	ldd XH,Y+CONTEXT_STACK_PTR+1
	in tmp_reg,_SFR_IO_ADDR(SREG)
	cli
	sts avr_thread_active,YL
	sts (avr_thread_active)+1,YH
	/* Load new stack pointer. */
#ifdef SPH
	out _SFR_IO_ADDR(SPH),XH
#endif
	out _SFR_IO_ADDR(SPL),XL

	/* Tell isr it's okay to switch again. */
	lds XL,avr_thread_disabled
	dec XL
	out _SFR_IO_ADDR(SREG),tmp_reg
	sts avr_thread_disabled,XL

	/* Restore SREG. */
	pop tmp_reg
        cbi tmp_reg,SREG_I
	out _SFR_IO_ADDR(SREG),tmp_reg

	/* Restore all registers. */
	POP_ALL

	reti
