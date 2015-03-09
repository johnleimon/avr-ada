###########################################################################
## The AVR-Ada Library is free software;  you can redistribute it and/or ##
## modify it under terms of the  GNU General Public License as published ##
## by  the  Free Software  Foundation;  either  version 2, or  (at  your ##
## option) any later version.  The AVR#Ada Library is distributed in the ##
## hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even ##
## the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR ##
## PURPOSE. See the GNU General Public License for more details.         ##
###########################################################################

MCU := atmega169

#put the name of the target files here (without extension)
TRGS	  := main_out

# source files
SRCS      := $(addsuffix .adb, $(TRGS))

# GNAT project
PRJ	  := dataflash_test.gpr

# switches for gnatmake
MFLAGS    := -XMCU=$(MCU)

###### define some programs #######
RM	  := rm -rf
RN	  := mv
BIN	  := avr-objcopy
DUMP	  := avr-objdump
SIZE      := avr-size
GNATMAKE  := avr-gnatmake

###### output format can be srec, ihex (avrobj is always created) #######
FORMAT = ihex
# ------------------------------------------

# other intersting file formats
TRGS_ELF  := $(addsuffix .elf, $(TRGS))
TRGS_ROM  := $(addsuffix .hex, $(TRGS))
TRGS_EEP  := $(addsuffix .eep, $(TRGS))
TRGS_LSS  := $(addsuffix .lss, $(TRGS))

# --- this defines the targets of the make process ---
all:	$(TRGS_ELF) $(TRGS_ROM) $(TRGS_EEP) $(TRGS_LSS) size ok


%.prog: %.hex %.eep
	avrdude.exe -p m169 -c butterfly -P com4 -U flash:w:$*.hex

.PHONY: main.elf

# --- build and link using gnatmake ---
$(TRGS_ELF): $(SRCS) $(PRJ) obj
	$(GNATMAKE) $(MFLAGS) -P$(PRJ) --RTS=rts/$(MCU)

# --- create bin (.hex and .eep) files from elf output file ---
%.hex: %.elf
	$(BIN) -O $(FORMAT) -R .eeprom $< $@

%.eep: %.elf
	-$(BIN) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O $(FORMAT) $< $@

# --- create a symbol table
%.sym: %.elf
	avr-nm -n $< > $@

# --- create extended listing
%.lss: %.elf
	$(DUMP) -h -S $< > $@

# --- what is the size of the various sections
size:  $(TRGS_ELF)
	$(SIZE) -x -C --mcu=$(MCU) $^

obj:
	$(RM) obj
	mkdir obj

# --- make instruction to delete created files ---
clean:
	$(RM) *.o
	$(RM) *.ali
	$(RM) *.map
	$(RM) *.elf
	$(RM) *.eep
	$(RM) *.lss
	$(RM) *.rom
	$(RM) *.obj
	$(RM) *.hex
	$(RM) b_*.c
	$(RM) obj/*
