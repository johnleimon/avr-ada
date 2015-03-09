//
// avr-thread-asm
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread-asm.h,v 1.3 2008-09-04 01:10:00 dean Exp $
// Dean Ferreyra

// Included by assembly code.

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

#define RETURN_SIZE 2
#define REGISTERS_SIZE 32
#define SREG_SIZE 1
#define CONTEXT_SIZE (REGISTERS_SIZE + SREG_SIZE)
#define SWITCH_SIZE (RETURN_SIZE + CONTEXT_SIZE)

#include "context-offsets.h"

#define PUSH_ALL   \
	push r31 $ \
	push r30 $ \
	push r29 $ \
	push r28 $ \
	push r27 $ \
	push r26 $ \
	push r25 $ \
	push r24 $ \
	push r23 $ \
	push r22 $ \
	push r21 $ \
	push r20 $ \
	push r19 $ \
	push r18 $ \
	push r17 $ \
	push r16 $ \
	push r15 $ \
	push r14 $ \
	push r13 $ \
	push r12 $ \
	push r11 $ \
	push r10 $ \
	push r9	 $ \
	push r8	 $ \
	push r7	 $ \
	push r6	 $ \
	push r5	 $ \
	push r4	 $ \
	push r3	 $ \
	push r2	 $ \
	push r1	 $ \
	push r0

#define POP_ALL    \
	pop r0	 $ \
	pop r1	 $ \
	pop r2	 $ \
	pop r3	 $ \
	pop r4	 $ \
	pop r5	 $ \
	pop r6	 $ \
	pop r7	 $ \
	pop r8	 $ \
	pop r9	 $ \
	pop r10	 $ \
	pop r11	 $ \
	pop r12	 $ \
	pop r13	 $ \
	pop r14	 $ \
	pop r15	 $ \
	pop r16	 $ \
	pop r17	 $ \
	pop r18	 $ \
	pop r19	 $ \
	pop r20	 $ \
	pop r21	 $ \
	pop r22	 $ \
	pop r23	 $ \
	pop r24	 $ \
	pop r25	 $ \
	pop r26	 $ \
	pop r27	 $ \
	pop r28	 $ \
	pop r29	 $ \
	pop r30	 $ \
	pop r31

#define PUSH_ALL_BUT_Z   \
	push r29 $ \
	push r28 $ \
	push r27 $ \
	push r26 $ \
	push r25 $ \
	push r24 $ \
	push r23 $ \
	push r22 $ \
	push r21 $ \
	push r20 $ \
	push r19 $ \
	push r18 $ \
	push r17 $ \
	push r16 $ \
	push r15 $ \
	push r14 $ \
	push r13 $ \
	push r12 $ \
	push r11 $ \
	push r10 $ \
	push r9	 $ \
	push r8	 $ \
	push r7	 $ \
	push r6	 $ \
	push r5	 $ \
	push r4	 $ \
	push r3	 $ \
	push r2	 $ \
	push r1  $ \
        push r0


