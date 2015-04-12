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

set -x

GNATPREFIX=$PWD/gnat-native-47
AVRADAPREFIX=$PWD/avr-ada-47
TOPDIR=$PWD

GCC_VERSION=4.7.2
AVR_GCC_VERSION=4.7.2

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

# GCC 4.7.x is required for building AVR-Ada 1.2.
build_gcc47()
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
      ADAC=gcc-4.6 CC=gcc-4.6 ../gcc-${GCC_VERSION}/configure --enable-languages=c,ada --prefix=$GNATPREFIX --disable-multilib --without-cloog --without-ppl || fail "gcc: configure"
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

#  echo "++++++++++++++++ UNIQUE_00 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_00 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_00
#  fi

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

#  echo "++++++++++++++++ UNIQUE_01 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_01 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_01
#  fi
}

build_avrgcc()
{
  echo "------------------------------------------"
  echo " build_avrgcc()"
  echo "------------------------------------------"

#  echo "++++++++++++++++ UNIQUE_02 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_02 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_02
#  fi

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
  for a in ../../avr-ada/patches/gcc/4.7.2/*.patch;do patch -p0 < $a;done
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

#  echo "++++++++++++++++ UNIQUE_03 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_03 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_03
#  fi
}

build_avrlibc()
{
  echo "------------------------------------------"
  echo " build_avrlibc()"
  echo "------------------------------------------"

#  echo "++++++++++++++++ UNIQUE_04 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_04 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_04
#  fi

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

#  echo "++++++++++++++++ UNIQUE_05 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_05 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_05
#  fi
}

build_avrada()
{
  echo "------------------------------------------"
  echo " build_avrada()"
  echo "------------------------------------------"

  cd $TOPDIR
  export PATH="$AVRADAPREFIX/bin":$PATH

#  echo "++++++++++++++++ UNIQUE_06 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_06 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_06
#  fi

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

#  echo "++++++++++++++++ UNIQUE_07 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_07 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_07
#  fi

  ./configure                                             # OPERATION_00

#  echo "++++++++++++++++ UNIQUE_08 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_08 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_08
#  fi

  make GPRCONFIG=/usr/bin/gprconfig GPRBUILD=/usr/bin/gprbuild || fail "avr-ada: make"                            # OPERATION_01

#  echo "++++++++++++++++ UNIQUE_09 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_09 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_09
#  fi

  # Clean up from a previous build #
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr25
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr3
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr31
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr35
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr4
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr5
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr51
  rm -rfv  $AVRADAPREFIX/lib/gcc/avr/4.7.2/avr6

  make install_rts || fail "avr-ada: make install_Rts"    # OPERATION_02

#  echo "++++++++++++++++ UNIQUE_10 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_10 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_10
#  fi

  cd avr/avr_lib || fail "avr-ada: cd avr/avr_lib"
  make || fail "avr-ada: make lib"                        # OPERATION_03

#  echo "++++++++++++++++ UNIQUE_11 ++++++++++++++++"
#  if [ ! -f $TOPDIR/UNIQUE_11 ]; then
#    find $TOPDIR > $TOPDIR/UNIQUE_11
#  fi

  cd ..
  make install_libs || fail "avr-ada: make install_libs"  # OPERATION_04

#   echo "++++++++++++++++ UNIQUE_12 ++++++++++++++++"
#   if [ ! -f $TOPDIR/UNIQUE_12 ]; then
#     find $TOPDIR > $TOPDIR/UNIQUE_12
#   fi

  cd ..
}

#   echo "++++++++++++++++ UNIQUE_13 ++++++++++++++++"
#   if [ ! -f $TOPDIR/UNIQUE_13 ]; then
#     find $TOPDIR > $TOPDIR/UNIQUE_13
#   fi

build_gcc47

#   echo "++++++++++++++++ UNIQUE_14 ++++++++++++++++"
#   if [ ! -f $TOPDIR/UNIQUE_14 ]; then
#     find $TOPDIR > $TOPDIR/UNIQUE_14
#   fi

build_avrbinutils

build_avrgcc

build_avrlibc

build_avrada

