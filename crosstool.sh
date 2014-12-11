#!/usr/bin/bash
#
# File: crosstool.sh
# Created: 06, December 2014
# 
# Copyright (C) 2014 Jarielle Catbagan
#
# Licensed under BSD License
#
#
# Description:
#
# Obtains the necessary packages for configuring and building either a native- or a cross-compiler
# and then installing them in the appropriate directories.
#
# Please see configuration.txt accompanied with this file for the details/motivations behind the
# various options used during the configuration process of the various packages.

BINUTILS_VERSION="2.24"
GCC_VERSION="4.9.2"
GLIBC_VERSION="2.20"
CROSSTOOL_RELPATH=opt/crosstool
LOG=$HOME/crosstool-config.log


log()
{
	echo -e "`date`: $@" >> $LOG
	return 0
}

abort()
{
	log "error: " $@
	exit 1
}

if [ -z $HOST ]; then
	export HOST=x"x86-unknown-linux-gnu"
fi

if [ -z $TARGET ]; then
	export TARGET="arm-unknown-linux-gnueabihf"
fi

if [ -z $SYSROOT ]; then
	export SYSROOT=${HOME}/${CROSSTOOL_RELPATH}
fi

if [ -z $PREFIX ]; then
	export PREFIX=${SYSROOT}/usr
fi

echo $PATH | grep "${PREFIX}/bin" - 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	export PATH=$PREFIX/bin:$PATH
fi


# verify if the recommended location for installing the final binaries exist
# if not make the appropriate directories, otherwise remove everything so we can start anew
cd $HOME
if [ ! -d $PREFIX ]; then
	mkdir -p $CROSSTOOL_RELPATH/usr
else
	cd $CROSSTOOL_RELPATH
	rm -rf *
	mkdir usr
fi	


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# install kernel headers
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm -f $LOG
echo -e "cross-toolchain configuration log file\n" > $LOG

log "installing kernel headers in ${PREFIX}"
cd $HOME/linux
make ARCH=arm INSTALL_HDR_PATH=$PREFIX headers_install
if [ $? -eq 0 ]; then
	log "kernel headers installed"
else
	abort "failed to install kernel headers"
fi


cd $HOME
# let's start a clean slate, so remove and make the respective 'build' directories unconditionally
rm -rf build-binutils build-gcc build-glibc
mkdir build-binutils build-gcc build-glibc
cd build-gcc
if [ $? -eq 0 ]; then
	mkdir build-gcc-pre build-gcc-final
fi


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# build and install cross-binutils
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "building binutils for ${TARGET}"
cd $HOME/build-binutils
../binutils-${BINUTILS_VERSION}/configure --build=$HOST --host=$HOST --target=$TARGET \
	--with-sysroot=$SYSROOT --prefix=$PREFIX --disable-multilib --disable-nls --disable-werror
make
if [ $? -eq 0 ]; then
	log "binutils built; installing binutils in ${PREFIX}"
else
	abort "failed to build binutils"
fi
make install
if [ $? -eq 0 ]; then
	log "binutils installed" 
else
	abort "failed to install binutils"
fi


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# build and install gcc stage-1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "building gcc stage-1 for ${TARGET} with ${PREFIX} as the system root directory"
cd $HOME/build-gcc/build-gcc-pre
../../gcc-${GCC_VERSION}/configure --build=$HOST --host=$HOST --target=$TARGET --with-sysroot=$SYSROOT \
	--prefix=$PREFIX --with-local-prefix=/usr --with-native-system-header-dir=/usr/include \
	--without-headers --with-newlib --disable-shared --disable-threads --disable-multilib \
	--disable-libgomp --disable-libquadmath --disable-libsanitizer --disable-libssp \
	--enable-languages=c
make all-gcc
if [ $? -eq 0 ]; then
	log "gcc stage-1 built; installing in ${PREFIX}"
else
	abort "failed to build gcc stage-1"
fi
make install-gcc
if [ $? -eq 0 ]; then
	log "gcc stage-1 installed; building libgcc for gcc stage-1"
else
	abort "failed to install gcc stage-1"
fi
make all-target-libgcc
if [ $? -eq 0 ]; then
	log "libgcc built; installing in ${PREFIX}"
else
	abort "failed to build libgcc for gcc stage-1"
fi
make install-target-libgcc
if [ $? -eq 0 ]; then
	log "libgcc for gcc stage-1 installed"
else
	abort "failed to install libgcc for gcc stage-1"
fi


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# build and install glibc
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "building glibc for ${TARGET}"
cd $HOME/build-glibc
CC="${TARGET}-gcc" AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" ../glibc-${GLIBC_VERSION}/configure \
	--build=$HOST --host=$TARGET --prefix=$PREFIX --enable-kernel=2.6.32 \
	--with-binutils=$PREFIX/bin --with-headers=$PREFIX/include
make
if [ $? -eq 0 ]; then
	log "glibc built; installing in ${PREFIX}"
else
	abort "failed to build glibc"
fi
make install
if [ $? -eq 0 ]; then
	log "glibc installed"
else
	abort "failed to install glibc"
fi


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# build and install gcc final
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "building gcc final and requisites for ${TARGET} with ${PREFIX} as the system root directory"
cd $HOME/build-gcc/build-gcc-final
if [ $? -eq 0 ]; then
	rm -rf *
fi
../../gcc-${GCC_VERSION}/configure --build=$HOST --host=$HOST --target=$TARGET --with-sysroot=$PREFIX \
	--prefix=$PREFIX --with-local-prefix=/usr --with-native-system-header-dir=/usr/include \
	--disable-static --disable-nls --disable-multilib --enable-threads=posix \
	--enable-languages=c,c++
make AS_FOR_TARGET="${TARGET}-as" LD_FOR_TARGET="${TARGET}-ld"
if [ $? -eq 0 ]; then
	log "gcc final and requisites built; installing in ${PREFIX}"
else
	abort "failed to build gcc final and requisites"
fi
make install
if [ $? -eq 0 ]; then
	log "gcc final and requisites installed"
else
	abort "failed to install gcc final and requisites"
fi
