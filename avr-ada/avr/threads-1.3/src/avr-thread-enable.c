//
// avr-thread-enable
//
// Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
//
// $Id: avr-thread-enable.c,v 1.4 2008-11-11 20:29:49 dean Exp $
// Dean Ferreyra

// Enabling and disabling preemptive multitasking.

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
#include "avr-thread.h"
#include "avr-thread-def.h"

