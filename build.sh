#
#  Copyright (c) 2014, 2015 Tero Koskinen
#  Copyright (c) 2015 John Leimon
#
#  Permission to use, copy, modify, and/or distribute this software for any purpose
#  with or without fee is hereby granted, provided that the above copyright notice and
#  this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD
#  TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN
#  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
#  CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
#  PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
#  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#!/bin/sh

# Uncomment for script verbose mode #
# set -x

TOPDIR=$PWD

LSB_REL=`lsb_release -i|tr "\t" " "|tr -s " "|cut -f3 -d" "`
if [ x"$LSB_REL" != x"" ]; then
  DISTRO=$LSB_REL;
else
  DISTRO=unknown
fi

fail()
{
  echo "ERROR:" $@
  exit 1
}

check_system()
{
  echo -n "Checking for GNAT"

  gnat > /dev/null 2>&1

  if [ $? -ne 0 ]
  then
    echo "............. Missing!"
    echo "Building AVR Ada requires a GNAT compiler."
    exit 1
  fi

  CONFIG_GNAT=`gnat 2>/dev/null | sed -n 1p | grep -wo -E "[0-9]*\.{1}[0-9]*\.*[0-9]*"`
  CONFIG_GNAT_MAJOR=`gnat 2>/dev/null | sed -n 1p | grep -wo -E "[0-9]*\.{1}[0-9]*"`
  CONFIG_GNAT_SHORT=`echo $CONFIG_GNAT_MAJOR | sed 's/\.//'`

  GNATPREFIX=$PWD/gnat-native-$CONFIG_GNAT_SHORT
  AVRADAPREFIX=$PWD/avr-ada-$CONFIG_GNAT_SHORT

  GCC_VERSION=$CONFIG_GNAT
  AVR_GCC_VERSION=$CONFIG_GNAT

  echo "............. OK [Version $CONFIG_GNAT]"
}

build_gcc()
{
  echo "------------------------------------------"
  echo " build_gcc47()"
  echo "------------------------------------------"

  if [ -f "$GNATPREFIX/bin/gnatmake" ]; then
    echo "gcc ${GCC_VERSION} already build, skipping"
    return 0
  fi

  if [ ! -f gcc-${GCC_VERSION}.tar.gz ]; then
    wget ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
  fi

  # Uncompress GCC archive #
  if [ ! -d gcc-${GCC_VERSION} ]; then
    tar zxf gcc-${GCC_VERSION}.tar.gz
  else
    echo "gcc-${GCC_VERSION} exists... skipping un-archive operation"
  fi

  # Search for the texinfo patch #
  if [ -f texinfo.patch ]; then
    PATCH_PATH="../"
  elif [ -f ../texinfo.patch ]; then
    PATCH_PATH="../../"
  else
    echo "Error: Could not find texinfo patch"
    exit 1
  fi

  # Determine if we need to patch texinfo #
  cd gcc-${GCC_VERSION}
  patch -p0 --dry-run --silent < $PATCH_PATH/texinfo.patch 2>&1 > /dev/null
  if [ $? -eq 0 ]; then
    # Apply the patch #
    echo "Applying TEXINFO patch"
    patch -p0 -N < $PATCH_PATH/texinfo.patch || fail "GCC -- Texinfo patch"
    patch -p0 -N < $PATCH_PATH/texinfo2.patch || fail "GCC -- Texinfo 2 patch"
  else 
    echo "TEXINFO is already patched... skipping patch"
  fi
  cd ..

  rm -rf gcc-obj-${GCC_VERSION}
  mkdir gcc-obj-${GCC_VERSION} && cd gcc-obj-${GCC_VERSION} || fail "cd gcc-obj-${GCC_VERSION}"

  ### i386 Hardware ###
  if [ -d /usr/lib/i386-linux-gnu/ ]; then
    export LIBRARY_PATH=/usr/lib/i386-linux-gnu/
  fi
  if [ -d /usr/include/i386-linux-gnu ]; then
    export C_INCLUDE_PATH=/usr/include/i386-linux-gnu
    export CPATH=/usr/include/i386-linux-gnu
    export CPLUS_INCLUDE_PATH=/usr/include/i386-linux-gnu
  fi

  ### x86_64 Hardware ###
  if [ -d /usr/lib/x86_64-linux-gnu/ ]; then
    export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/
  fi
  if [ -d /usr/include/x86_64-linux-gnu ]; then
    export C_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
    export CPATH=/usr/include/x86_64-linux-gnu
    export CPLUS_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
  fi

  echo "LIBRARY_PATH       = '$LIBRARY_PATH'"
  echo "C_INCLUDE_PATH     = '$C_INCLUDE_PATH'"
  echo "CPLUS_INCLUDE_PATH = '$CPLUS_INCLUDE_PATH'"
  echo "CPATH              = '$CPATH'"

  echo "Distribution: $DISTRO"

  case "$DISTRO" in
    Debian|Ubuntu|LinuxMint)
      ADAC=gcc-$CONFIG_GNAT_MAJOR CC=gcc-$CONFIG_GNAT_MAJOR ../gcc-${GCC_VERSION}/configure --enable-languages=c,ada --prefix=$GNATPREFIX --disable-multilib --without-cloog --without-ppl || fail "gcc: configure"
      ;;
    *)
      ../gcc-${GCC_VERSION}/configure --enable-languages=c,ada --prefix=$GNATPREFIX || fail "gcc: configure"
      ;;
  esac
  make bootstrap || fail "gcc: make bootstrap"
  make install || fail "gcc: make install"
  cd ..

}

build_avrbinutils()
{
  echo "------------------------------------------"
  echo " build_avrbinutils()"
  echo "------------------------------------------"

  cd $TOPDIR
  if [ -f $AVRADAPREFIX/bin/avr-as ]; then
    echo "avr-binutils already installed, skipping"
    return 0
  fi

  pwd
  ls -l

  tar jxf binutils-2.20.1a.tar.bz2 || fail "binutils: tar"
  cd binutils-2.20.1
  for a in ../avr-ada/patches/binutils/2.20.1/*.patch;
  do
    patch -p0 < $a || fail "avr-binutils: patch $a"
  done
  sed -i -e 's/@colophon/@@colophon/' \
    -e 's/doc@cygnus.com/doc@@cygnus.com/' bfd/doc/bfd.texinfo

  cd ..

  rm -rf binutils-obj
  mkdir binutils-obj && cd binutils-obj || fail "binutils: mkdir/cd"
  ../binutils-2.20.1/configure --target=avr --program-prefix=avr- \
    --disable-shared --disable-nls --enable-commonbfdlib=no \
    --disable-werror \
    --prefix=$AVRADAPREFIX || fail "binutils: configure"
        sed -i -e 's/SUBDIRS = doc po/SUBDIRS = po/' gas/Makefile
        sed -i -e 's/SUBDIRS = doc po/SUBDIRS = po/' ../binutils-2.20.1/gas/Makefile.am
        sed -i -e 's/SUBDIRS = /SUBDIRS = #/' ../binutils-2.20.1/gas/Makefile.in
  make || fail "binutils: make"
  make install || fail "binutils: make install"
}

build_avrgcc()
{
  echo "------------------------------------------"
  echo " build_avrgcc()"
  echo "------------------------------------------"

  echo "GNATPREFIX = '$GNATPREFIX' AVRADAPREFIX = '$AVRADAPREFIX'"

  cd $TOPDIR
  export PATH="$GNATPREFIX/bin":"$AVRADAPREFIX/bin":$PATH

  mkdir avr
  if [ -d gcc-${AVR_GCC_VERSION} ]; then
    echo "Removing old gcc-${AVR_GCC_VERSION} dir"
    rm -rf gcc-${AVR_GCC_VERSION}
  fi
  if [ ! -f gcc-${AVR_GCC_VERSION}.tar.gz ]; then
    wget ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${AVR_GCC_VERSION}/gcc-${AVR_GCC_VERSION}.tar.gz
  fi
  if [ -f "$AVRADAPREFIX/bin/avr-gnatmake" ]; then
    echo "avr-gcc already installed, skipping"
    return 0
  fi

  cd $TOPDIR/avr

  ### i386 Hardware ###
  if [ -d /usr/lib/i386-linux-gnu/ ]; then
    export LIBRARY_PATH=/usr/lib/i386-linux-gnu/
  fi
  if [ -d /usr/include/i386-linux-gnu ]; then
    export C_INCLUDE_PATH=/usr/include/i386-linux-gnu
    export CPATH=/usr/include/i386-linux-gnu
    export CPLUS_INCLUDE_PATH=/usr/include/i386-linux-gnu
  fi

  ### x86_64 Hardware ###
  if [ -d /usr/lib/x86_64-linux-gnu/ ]; then
    export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/
  fi
  if [ -d /usr/include/x86_64-linux-gnu ]; then
    export C_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
    export CPATH=/usr/include/x86_64-linux-gnu
    export CPLUS_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
  fi

  tar zxf $TOPDIR/gcc-${AVR_GCC_VERSION}.tar.gz || fail "avr-gcc: tar"
  cd gcc-${AVR_GCC_VERSION} || fail "avr-gcc: cd"
  pwd
  for a in ../../avr-ada/patches/gcc/$AVR_GCC_VERSION/*.patch;do patch -p0 < $a;done
  cd ..
  rm -rf avr-gcc-obj

  mkdir avr-gcc-obj && cd avr-gcc-obj || fail "avr-gcc: mkdir/cd"
  ../gcc-${AVR_GCC_VERSION}/configure --target=avr --program-prefix=avr- \
    --disable-shared --disable-nls --disable-libssp \
    --with-system-zlib \
    --disable-libada \
    --enable-multilib \
    MAKEINFO=missing \
    --enable-languages=ada,c,c++ --enable-cpp --with-dwarf2 \
    --enable-version-specific-runtime-libs \
    --prefix=$AVRADAPREFIX || fail "avr-gcc: configure"
  sed -i -e 's/$(STAMP)/echo timestamp >/' ../gcc-${AVR_GCC_VERSION}/gcc/config/avr/t-avr
  make || fail "avr-gcc: make"
  make install || fail "avr-gcc: make install"
  cd ..
  cd $TOPDIR

  if [ ! -f "$AVRADAPREFIX/bin/avr-gnatmake" ]; then
    echo "avr-gnatmake build failed!"
    exit 1
  fi
}

build_avrlibc()
{
  echo "------------------------------------------"
  echo " build_avrlibc()"
  echo "------------------------------------------"

  cd $TOPDIR
  export PATH="$AVRADAPREFIX/bin":$PATH
  if [ ! -f avr-libc-1.8.0.tar.bz2 ]; then
    wget http://download.savannah.gnu.org/releases/avr-libc/avr-libc-1.8.0.tar.bz2
  fi
  if [ -f "$AVRADAPREFIX/avr/lib/avr3/libc.a" ]; then
    echo "avr-libc installed, skipping"
    return 0
  fi
  rm -rf avr-libc-1.8.0
  tar jxf avr-libc-1.8.0.tar.bz2 || fail "avr-libc: tar"
  cd avr-libc-1.8.0 || fail "avr-libc: cd"
  ./configure --host=avr --prefix=$AVRADAPREFIX || fail "avr-libc: configure"
  make || fail "avr-libc: make"
  make install || fail "avr-libc: make install"
  cd ..
}

build_avrada()
{
  echo "------------------------------------------"
  echo " build_avrada()"
  echo "------------------------------------------"

  cd $TOPDIR
  export PATH="$AVRADAPREFIX/bin":$PATH

  # Search for the texinfo patch #
  if [ -f avr-threads.diff ]; then
    PATCH_PATH="../"
  elif [ -f ../avr-threads.diff ]; then
    PATCH_PATH="../../"
  else
    echo "Error: Could not find 'avr-threads.diff' patch"
    exit 1
  fi

  cd avr-ada
  patch -p1 --dry-run --silent < $PATCH_PATH/avr-threads.diff 2>&1 > /dev/null
  if [ $? -eq 0 ]; then
    # Apply the patch #
    echo "Applying AVR threads patch"
    patch -p1 -N < $PATCH_PATH/avr-threads.diff || fail "AVR Ada threads"
  else
    echo "AVR threads is already patched... skipping patch"
  fi
  cd ..

  cd avr-ada || fail "avr-ada: cd"
  sed -i -e 's/stamp-libs: $(LIB_LIST) $(BOARD_LIB_LIST) $(THREAD_LIB_LIST)/stamp-libs: $(LIB_LIST) $(BOARD_LIB_LIST)/' avr/avr_lib/Makefile

  ./configure                                             # OPERATION_00

  make GPRCONFIG=/usr/bin/gprconfig GPRBUILD=/usr/bin/gprbuild || fail "avr-ada: make"                            # OPERATION_01

  # Clean up from a previous build #
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr25
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr3
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr31
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr35
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr4
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr5
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr51
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/$CONFIG_GNAT/avr6

  make install_rts || fail "avr-ada: make install_Rts"    # OPERATION_02

  cd avr/avr_lib || fail "avr-ada: cd avr/avr_lib"
  make || fail "avr-ada: make lib"                        # OPERATION_03

  cd ..
  make install_libs || fail "avr-ada: make install_libs"  # OPERATION_04

  cd ..
}

check_build()
{
  if [ -f $AVRADAPREFIX/bin/avr-gnatmake ];then
    echo "......................................................"
    echo " AVR Ada build complete"
    echo ""
    echo " Binaries are located at:"
    echo " $AVRADAPREFIX/bin"
    echo "......................................................"
  else 
    echo "AVR Ada build did not complete sucessfully"
  fi
}

check_system

build_gcc

build_avrbinutils

build_avrgcc

build_avrlibc

build_avrada

check_build
