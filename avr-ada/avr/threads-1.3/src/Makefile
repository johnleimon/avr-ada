#
# Makefile
#
# Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
#
# $Id: Makefile,v 1.5 2008-11-11 19:04:40 dean Exp $
# Dean Ferreyra

# This file is part of AVR-THREADS.
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; see the file COPYING.LIB.  If not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite
# 330, Boston, MA 02111-1307  USA

# Contact information:
#
# Dean Ferreyra
# 12902 Malena Drive
# Santa Ana, CA 92705-1102  USA
#
# dean@octw.com

include common.mk

all: avr5-lib avr3-lib avr2-lib

install: avr5-lib-install avr3-lib-install avr2-lib-install
	install -m644 avr-thread.h ${includedir}

avr2-lib: avr2-debug avr2
	cp common.mk avr2-debug
	cd avr2-debug; $(MAKE) -f ../Makefile AVR_ARCH=2 DEBUG_STACK_USAGE=1 libavr-thread-debug.a
	cp common.mk avr2
	cd avr2; $(MAKE) -f ../Makefile AVR_ARCH=2 DEBUG_STACK_USAGE=0 libavr-thread.a

avr3-lib: avr3-debug avr3
	cp common.mk avr3-debug
	cd avr3-debug; $(MAKE) -f ../Makefile AVR_ARCH=3 DEBUG_STACK_USAGE=1 libavr-thread-debug.a
	cp common.mk avr3
	cd avr3; $(MAKE) -f ../Makefile AVR_ARCH=3 DEBUG_STACK_USAGE=0 libavr-thread.a

avr5-lib: avr5-debug avr5
	cp common.mk avr5-debug
	cd avr5-debug; $(MAKE) -f ../Makefile AVR_ARCH=5 DEBUG_STACK_USAGE=1 libavr-thread-debug.a
	cp common.mk avr5
	cd avr5; $(MAKE) -f ../Makefile AVR_ARCH=5 DEBUG_STACK_USAGE=0 libavr-thread.a

avr2-lib-install: avr2-lib
	install -m644 avr2-debug/libavr-thread-debug.a ${libdir}
	install -m644 avr2/libavr-thread.a ${libdir}

avr3-lib-install: avr3-lib
	install -m644 avr3-debug/libavr-thread-debug.a ${libdir}/avr3
	install -m644 avr3/libavr-thread.a ${libdir}/avr3

avr5-lib-install: avr5-lib
	install -m644 avr5-debug/libavr-thread-debug.a ${libdir}/avr5
	install -m644 avr5/libavr-thread.a ${libdir}/avr5

avr2:
	mkdir $@
avr2-debug:
	mkdir $@
avr3:
	mkdir $@
avr3-debug:
	mkdir $@
avr5:
	mkdir $@
avr5-debug:
	mkdir $@

clean distclean:
	-rm -rf avr2-debug avr2 avr3-debug avr3 avr5-debug avr5

%.o : %.c ; $(CC) $(CFLAGS) -c -o $*.o $<

%.o : %.S ; $(CC) $(AFLAGS) -c -o $*.o $<

%.s: %.c ; $(CC) $(CFLAGS) -S -o $*.s $<

% : RCS/%,v

$(LIB_NAME): avr-thread.o avr-thread-enable.o \
	avr-thread-stop.o avr-thread-sleep.o \
	avr-thread-mutex.o avr-thread-mutex-basic.o \
	avr-thread-event.o \
	avr-thread-isr.o avr-thread-switch.o
	${AR} rcv $@ $?

avr-thread.o: avr-thread.c avr-thread.h avr-thread-def.h avr-thread-asm.h

avr-thread-enable.o: avr-thread-enable.c avr-thread.h avr-thread-def.h

avr-thread-stop.o: avr-thread-stop.c avr-thread.h avr-thread-def.h \
	avr-thread-asm.h

avr-thread-sleep.o: avr-thread-sleep.c avr-thread.h avr-thread-def.h \
	avr-thread-asm.h

avr-thread-event.o: avr-thread-event.c avr-thread.h avr-thread-def.h \
	avr-thread-asm.h

avr-thread-mutex.o: avr-thread-mutex.c avr-thread.h avr-thread-def.h \
	avr-thread-asm.h

avr-thread-mutex-basic.o: avr-thread-mutex-basic.c avr-thread.h \
	avr-thread-def.h avr-thread-asm.h

avr-thread-switch.o: avr-thread-switch.S avr-thread-asm.h

avr-thread-isr.o: avr-thread-isr.S avr-thread-asm.h
