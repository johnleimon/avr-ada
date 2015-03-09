###########################################################################
## The AVR-Ada Library is free software;  you can redistribute it and/or ##
## modify it under terms of the  GNU General Public License as published ##
## by  the  Free Software  Foundation;  either  version 2, or  (at  your ##
## option) any later version.  The AVR-Ada Library is distributed in the ##
## hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even ##
## the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR ##
## PURPOSE.  See the GNU General Public License for more details.        ##
###########################################################################

# avr/Makefile builds the AVR-Ada Library

###############################################################
#
#  Top
#
all: build_libs
clean: clean_libs
install: install_libs
uninstall: uninstall_libs

.PHONY: all clean install uninstall


###############################################################
#
#  Config
#
../config:
	$(MAKE) -C .. config

include ../config


###############################################################
#
#  Settings
#
include ../excldevs.mk

MCU_LIST := $(filter-out $(excluded_parts), $(shell (cd avr_lib; ls -d at*)))

BOARD_LIST = \
	arduino_uno \
	xbeeimu \
	teensyplusplus2 \
	sparkfun8u2


# Additional libraries to install (don't appear to be built)
EXTRA_LIB_NAMES := crc debug fs lcd mcp4922 onewire sensirion slip
EXTRA_LIB_OBJS  := $(patsubst %,%/obj, $(EXTRA_LIB_NAMES))
EXTRA_LIB_LIBS  := $(patsubst %,%/lib, $(EXTRA_LIB_NAMES))
EXTRA_LIB_GPRS  := $(patsubst %,%_lib.gpr, $(EXTRA_LIB_NAMES))

# Items to install
INSTALL_SRCS = avr_lib/*.ad[sb] avr_lib/*/*.ad[sb] avr_lib/*/*.gpr \
   avr_lib/*/*.adc
INSTALL_GPRS = avr_tools.gpr avr_lib.gpr threads_lib.gpr mcu.gpr gnat.adc \
   avr_app.gpr $(EXTRA_LIB_GPRS)
INSTALL_LIBS := $(patsubst %,avr_lib/%/lib, $(MCU_LIST)) \
   $(patsubst %,avr_lib/%/thread-lib, $(MCU_LIST)) \
   $(patsubst %,avr_lib/board-%/lib, $(BOARD_LIST))
INSTALL_OBJS := $(patsubst %,avr_lib/%/obj, $(MCU_LIST)) \
   $(patsubst %,avr_lib/%/thread-obj, $(MCU_LIST)) \
   $(patsubst %,avr_lib/board-%/obj, $(BOARD_LIST))

# Modes for installed items
INSTALL_FILE_MODE = ugo=r
INSTALL_DIR_MODE = u=rwx,go=rx


###############################################################
#
#  Tools
#
RM      = rm -f
MKDIR   = mkdir
TAR     = tar
ECHO    = echo
CHMOD   = chmod
FIND    = find


###############################################################
#
#  Build
#
build_libs:
	$(MAKE) -C avr_lib $@

avr_lib/stamp-links:
	$(MAKE) -C avr_lib stamp-links

avr_lib/stamp-libs:
	$(MAKE) -C avr_lib stamp-libs

$(EXTRA_LIB_OBJS) $(EXTRA_LIB_LIBS) $(INSTALL_DIR):
	$(MKDIR) -p $@

.PHONY: build_libs


###############################################################
#
#  Clean
#
clean_libs: clean_avr_lib clean_extra_libs

clean_avr_lib:
	-$(MAKE) -C avr_lib clean_libs

clean_extra_libs:
	-$(RM) -rf $(EXTRA_LIB_LIBS)
	-$(RM) -rf $(EXTRA_LIB_OBJS)

.PHONY: clean_libs clean_avr_lib clean_extra_libs


###############################################################
#
#  Install
#

#
# Installation directory
#
# default search directories for gpr-files of gnatmake and gprbuild
# 1: <prefix>/<target>/lib/gnat (gprbuild requires --target)
# 2: <prefix>/share/gpr/
# 3: <prefix>/lib/gnat
PREFIX = $(RTS_BASE)/../../../..
INSTALL_DIR = $(PREFIX)/avr/lib/gnat

$(INSTALL_DIR):
	$(MKDIR) -p $@

#   restrict_permissions
restrict_permissions:
	$(CHMOD) -R a-w $(INSTALL_DIR)
	-chown -R root $(INSTALL_DIR) &>/dev/null

install_libs: $(INSTALL_DIR) avr_lib/stamp-links
	$(TAR) chf - $(INSTALL_GPRS) $(INSTALL_SRCS) $(INSTALL_OBJS) \
          $(INSTALL_LIBS) $(EXTRA_LIB_NAMES) \
	  | (cd $(INSTALL_DIR); $(TAR) xvf -)
	sed '/^ *for Externally_Built/,/end Threads_Lib;/d' < $(INSTALL_DIR)/threads_lib.gpr > $(INSTALL_DIR)/tmp_lib.gpr
	mv -f $(INSTALL_DIR)/tmp_lib.gpr $(INSTALL_DIR)/threads_lib.gpr
	echo '   for Externally_Built use "true";' >> $(INSTALL_DIR)/threads_lib.gpr
	echo 'end Threads_Lib;' >> $(INSTALL_DIR)/threads_lib.gpr
	$(FIND) $(INSTALL_DIR) -type f -exec $(CHMOD) $(INSTALL_FILE_MODE) '{}' \;
	$(FIND) $(INSTALL_DIR) -type d -exec $(CHMOD) $(INSTALL_DIR_MODE) '{}' \;

.PHONY: install_libs


###############################################################
#
#  Uninstall
#
uninstall_libs:
	$(RM) -r $(INSTALL_DIR)

.PHONY: uninstall_libs

-include $(Makefile_post)
