###########################################################################
## The AVR-Ada Library is free software;  you can redistribute it and/or ##
## modify it under terms of the  GNU General Public License as published ##
## by  the  Free Software  Foundation;  either  version 2, or  (at  your ##
## option) any later version.  The AVR-Ada Library is distributed in the ##
## hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even ##
## the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR ##
## PURPOSE.  See the GNU General Public License for more details.        ##
###########################################################################

# avr/avr_lib/Makefile builds the AVR-Ada MCUs & Boards

###############################################################
#
#  Top
#
all: build_libs
clean: clean_libs

.PHONY: all clean


###############################################################
#
#  Config
#
../../config:
	$(MAKE) -C ../.. config

include ../../config


###############################################################
#
#  Settings
#
include ../../excldevs.mk

# list of primary devices
PRIMARY_MCU_LIST := atmega32 atmega164p attiny2313 atmega8 atmega8u2 atmega168 atmega169 \
   atmega328p atmega644p atmega2560 at90usb1286 attiny85

# list of all supported devices
# MCU_LIST = $(filter-out $(excluded_parts), $(shell (ls -d at*)))
MCU_LIST = $(PRIMARY_MCU_LIST)

BOARD_LIST = \
   arduino_uno \
   xbeeimu \
   teensyplusplus2 \
   sparkfun8u2 \
   trinket3v

include boards.mk

# Library to build for each MCU
LIB = libavrada.a
THREAD_LIB = libavr-thread.a

# All libaries
# we build separate libraries for each supported device and each board (why?)
LIB_LIST := $(patsubst %, %/lib/$(LIB), $(MCU_LIST))
THREAD_LIB_LIST := $(patsubst %, %/thread-lib/$(THREAD_LIB), $(MCU_LIST))
BOARD_LIB_LIST := $(patsubst %, board-%/lib/$(LIB), $(BOARD_LIST))

# All part specific registers and definitions
MCU_SPECS := $(patsubst %, %/avr-mcu.ads, $(MCU_LIST))
BOARD_MCU_SPECS := $(patsubst %, board-%/avr-mcu.ads, $(BOARD_LIST))

# Point to our RTS
XRTS = -XRTS=$(CURDIR)/../../gcc-$(major).$(minor)-rts/

# Location of avr.cgpr if RTS has been installed
INSTALL_CGPR_DIR = $(PREFIX)/share/gpr


###############################################################
#
#  Tools
#
GNATMAKE  = avr-gnatmake
GPRBUILD  = gprbuild
GPRCONFIG = gprconfig
RM        = rm -f
MKDIR     = mkdir
ECHO      = echo


###############################################################
#
#  Build
#
build_libs: stamp-links stamp-libs

# first set the variable MCU
at%/avr-mcu.ads : MCU = $(patsubst %/avr-mcu.ads,%, $@)
at%/lib/$(LIB)  : MCU = $(patsubst %/lib/$(LIB),%, $@)
board-%/lib/$(LIB)  : MCU = $(patsubst board-%/lib/$(LIB),%, $@)
at%/thread-lib/$(THREAD_LIB): MCU = $(patsubst %/thread-lib/$(THREAD_LIB),%, $@)

at%/lib/$(LIB): stamp-links at%/obj at%/lib ../avr_lib.gpr ../avr_tools.gpr \
   ../mcu.gpr at%/avr-mcu.ads
	$(GNATMAKE) $(XRTS) -p -P../avr_lib.gpr -XMCU=$(MCU)

board-%/lib/$(LIB): stamp-links board-%/obj board-%/lib ../avr_lib.gpr \
   ../mcu.gpr board-%/avr-mcu.ads
	$(GNATMAKE) $(XRTS) -P../avr_lib.gpr -XBOARD=$(BOARD) -XMCU=$(MCU)

local-avr.cgpr: V := $(strip $(major).$(minor).$(patch))
local-avr.cgpr:
	$(GPRCONFIG) --batch --target=avr \
	  --config=Asm,$(V) \
	  --config=Asm2,$(V) \
	  --config=Asm_Cpp,$(V) \
	  --config=C,$(V) \
	  -o local-avr.cgpr

# rule for building the thread library
at%/thread-lib/$(THREAD_LIB): local-avr.cgpr at%/thread-obj at%/thread-lib \
   ../threads_lib.gpr ../mcu.gpr
	$(GPRBUILD) -p --config=local-avr.cgpr -P../threads_lib.gpr -XMCU=$(MCU)

at%/avr-mcu.ads board-%/avr-mcu.ads:
	$(ECHO) "pragma Style_Checks (Off);"  > $@
	$(ECHO) "with AVR.${MCU};"                    >> $@
	$(ECHO) "package AVR.MCU renames AVR.${MCU};" >> $@

at%/obj:
	$(MKDIR) -p $@

at%/lib:
	$(MKDIR) -p $@

at%/thread-obj:
	$(MKDIR) -p $@

at%/thread-lib:
	$(MKDIR) -p $@

board-%/obj:
	$(MKDIR) -p $@

board-%/lib:
	$(MKDIR) -p $@

stamp-links: $(MCU_SPECS) $(BOARD_MCU_SPECS)
	touch $@

stamp-libs: $(LIB_LIST) $(BOARD_LIB_LIST) $(THREAD_LIB_LIST)
	touch $@

.PHONY: build_libs

# don't delete these intermediate files
.PRECIOUS: at%/avr-mcu.ads at%/lib at%/obj board-%/avr-mcu.ads board-%/lib \
   board-%/obj at%/thread-lib at%/thread-obj


###############################################################
#
#  Clean
#
clean_libs:
	-$(RM) stamp-*
	-$(RM) -r at*/obj at*/lib
	-$(RM) -r at*/thread-obj at*/thread-lib
	-$(RM) -r board-*/obj board-*/lib
	-$(RM) at*/avr-mcu.ads board-*/avr-mcu.ads
	-$(RM) local-avr.cgpr

.PHONY: clean_libs


###############################################################
#
#  Implicit rules
#

# Create assembler files from Ada source files.
%.s : %.adb
	$(GNATMAKE) -f -u -P../avr_lib -XMCU=$(MCU) $< -cargs -S

%.s : %.ads
	$(GNATMAKE) -f -u -P../avr_lib -XMCU=$(MCU) $< -cargs -S

-include $(Makefile_post)
