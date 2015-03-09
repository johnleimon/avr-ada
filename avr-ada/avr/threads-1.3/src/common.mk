#
# common
#
# Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
#
# $Id: common.mk,v 1.8 2008-11-11 20:29:49 dean Exp $
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
# 
# Contact information:
# 
# Dean Ferreyra
# 12902 Malena Drive
# Santa Ana, CA 92705-1102  USA
# 
# dean@octw.com

CC=avr-gcc
AR=avr-ar
FLAGS=-Wall -Werror
LFLAGS=-Wl,-Map=$(<:.o=.map),--cref
CRT=-lc -lm

# Replace the prefix line below with the appropriate path to the AVR
# toolset.  Here are some examples:
#   prefix = /usr
#   prefix = /usr/local
#   prefix = c:/WinAVR
prefix = /usr/local

target = avr
prefix_avr = ${prefix}/${target}
bindir = ${prefix_avr}/bin
includedir = ${prefix_avr}/include
libdir = ${prefix_avr}/lib

ifeq ($(DEBUG_STACK_USAGE), 1)
    FLAGS += -DDEBUG_STACK_USAGE=1
    LIB_NAME = libavr-thread-debug.a
    L_NAME = avr-thread-debug
else
    LIB_NAME = libavr-thread.a
    L_NAME = avr-thread
endif

ifeq ($(AVR_ARCH),2)
    PART = at90s8515
    FLAGS += -Os
    VPATH=..
else
ifeq ($(AVR_ARCH),3)
    PART = atmega103
    FLAGS += -O2
    VPATH=..
else
ifeq ($(AVR_ARCH),5)
    PART = atmega128
    FLAGS += -Os
    VPATH=..
else
ifdef AVR_ARCH 
    $(error Unsupported architecture: $(AVR_ARCH))
endif
endif
endif
endif

FLAGS += -mmcu=$(PART) -I..

AFLAGS=$(FLAGS)
CFLAGS=$(FLAGS) -std=c99
