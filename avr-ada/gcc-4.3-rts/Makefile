#--------------------------------------------------------------------------
#- The AVR-Ada Library is free software;  you can redistribute it and/or --
#- modify it under terms of the  GNU General Public License as published --
#- by  the  Free Software  Foundation;  either  version 2, or  (at  your --
#- option) any later version.  The AVR-Ada Library is distributed in the --
#- hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even --
#- the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR --
#- PURPOSE. See the GNU General Public License for more details.         --
#-                                                                       --
#- As a special exception, if other files instantiate generics from this --
#- unit,  or  you  link  this  unit  with  other  files  to  produce  an --
#- executable   this  unit  does  not  by  itself  cause  the  resulting --
#- executable to  be  covered by the  GNU General  Public License.  This --
#- exception does  not  however  invalidate  any  other reasons why  the --
#- executable file might be covered by the GNU Public License.           --
#--------------------------------------------------------------------------

# This makefile compiles the AVR Ada run time system (RTS)

# Ada source files
ADASRC = ada.ads interfac.ads system.ads unchconv.ads a-unccon.ads \
   s-maccod.ads s-stoele.adb s-stoele.ads s-unstyp.ads \
   a-charac.ads a-chlat1.ads a-chlat9.ads \
   s-bitops.ads s-bitops.adb \
   gnat.ads g-souinf.ads \
   s-stalib.ads s-parame.ads \
   a-calend.ads a-caldel.ads
#   i-c.ads i-c.adb
#   a-except.ads a-except.adb
#  a-tags.ads a-tags.adb s-htable.ads s-htable.adb
#   a-stream.ads
#   s-finroo.ads s-finroo.adb a-finali.ads a-finali.adb
#   a-reatim.adb a-reatim.ads
#   a-interr.ads a-intnam.ads a-intsig.ads s-interr.adb s-interr.ads
#

OBJ = $(ADASRC:.ads=.o)

NOT_NEEDED_OBJS = ada.o interfac.o system.o s-maccod.o

LIBGNAT_OBJS = s-bitops.o # a-except.o
LIBGNAT_ALIS = $(ADASRC:.ads=.ali)

vpath %.ads adainclude
vpath %.adb adainclude

# includes to compile
INC	= -I- -Iadainclude

#compiler flags
ADAFLAGS = -g -Os -gnatn -gnatpg -mmcu=$(MCU)


###### define some variables based on the AVR base path in $(AVR) #######
CC	= avr-gcc
RM	= rm -f
COPY	= cp
AR	= avr-ar
RANLIB  = avr-ranlib
AS	= avr-as


# ------------------------------------------
-include ../config

ARCH_LIST := avr2 avr25 avr3 avr31 avr35 avr4 avr5 avr51 avr6

RTS_LIB_LIST := $(patsubst %, rts/%/adalib/libgnat.a, $(ARCH_LIST))
RTS_INC_LIST := $(patsubst %, rts/%/adainclude, $(ARCH_LIST))
RTS_SOURCE   := .


###############################################################
#
#  build the run time system (RTS)
#
build_rts: ${RTS_LIB_LIST}

rts/%/adalib/libgnat.a : MCU = $(patsubst rts/%/adalib/libgnat.a,%, $@)

rts/%/adalib/libgnat.a:
	$(MAKE) clean
	mkdir -p adalib
	$(MAKE) MCU=$(MCU) adalib/libgnat.a

	mkdir -p rts/$(MCU)/adainclude
	mkdir -p rts/$(MCU)/adalib

	cp -p $(RTS_SOURCE)/adainclude/*.ad? rts/$(MCU)/adainclude
	cp -p $(RTS_SOURCE)/adalib/*.ali     rts/$(MCU)/adalib
	cp -p $(RTS_SOURCE)/adalib/libgnat.a rts/$(MCU)/adalib
	$(MAKE) clean


###############################################################
#
#  install the RTS
#
install_rts: build_rts rtsclean
	cp -rp rts $(RTS_BASE)
	chmod -R a-w $(RTS_BASE)/rts
	-mkdir $(RTS_BASE)/adainclude
	cp $(RTS_SOURCE)/adainclude/system.ads $(RTS_BASE)/adainclude
	chmod a-w $(RTS_BASE)/adainclude/system.ads
	cp  $(RTS_SOURCE)/README.gnatlink_inst  $(RTS_BASE)/adainclude


###############################################################
#
#  remove RTS from the gcc tree
#
rtsclean:
	-chmod -R a+w $(RTS_BASE)/rts
	-rm -rf $(RTS_BASE)/rts

###############################################################
#
adalib/libgnat.a: $(LIBGNAT_OBJS) $(LIBGNAT_ALIS)
	$(AR) cr $@ $(LIBGNAT_OBJS)
	$(RANLIB) $@

empty.o: empty.c
	$(CC) -c $^ -o $@

empty.c:
	echo > $@

# keep the order of the following two implicit rules.  This way it
# tries to build a .ali first from .adb if available.  Only if there
# is no .adb, it tries to build from .ads.
%.ali %.o : %.adb
	$(CC) -c $(ADAFLAGS) $(INC) $<
	$(COPY) $@ adalib

%.ali %.o : %.ads
	$(CC) -c $(ADAFLAGS) $(INC) $<
	$(COPY) $@ adalib

# --- make instruction to delete created files ---
clean:
	$(RM) -f *.o
	$(RM) -f *.ali
	$(RM) -f empty.c
	-$(RM) -f adalib/*.o
	-$(RM) -f adalib/*.ali
	-$(RM) -f adalib/libgnat.a


###############################################################
#
#  Makefile stuff
#
.PHONY: clean rtsclean install_rts

print-%:
	@echo $* = $($*)

.PHONY: printvars

printvars:
	@$(foreach V,$(sort $(.VARIABLES)), \
           $(if $(filter-out environment% default automatic, \
           $(origin $V)),$(warning $V=$($V) ($(value $V)))))
