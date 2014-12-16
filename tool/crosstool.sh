#!/usr/bin/bash
#
# File: arm-unknown-linux-gnueabihf.sh
# Created: 06, December 2014
# 
# Copyright (C) 2014 Jarielle Catbagan
#
# Licensed under BSD License
#
#
# Synopsis:
#
# This script configures a toolchain specifically targeting the target platform specified with the 
# parameters listed below.
#
# The host platform that this toolchain will run is determined by the -n/--native or -c/--cross options.
# Both options must not be specified at the same time.  The toolchain will be built on the platform that
# this script is invoked on and may not be the same as the host platform where the toolchain will 
# eventually run.
#
# In the context of this configuration script, the meaning of the options differ than what they are 
# normally referred to. -n/--native specify that the toolchain will run on the platform that it is 
# built on.  On the other hand -c/--cross specify that the toolchain will run on the platform
# that the toolchain is targeting.  In other words, a native toolchain is being built for the 
# target platform. An intermediary platform might be added in the future where a toolchain is 
# built on the platform that this script is invoked on to run on a different architecture which in turn
# is targeting a different architecture as well.
#
# The motivation in the approach of this script is to focus on building a toolchain specifically 
# optimized for a specific target.  Consequently, this is not a general toolchain configuration.
# Furthermore, all platforms have different features and must be configured in a specific way in order
# to exploit those features.  As the architectures that are involved increase over time, a specific
# configuration will be developed.
#
# The toolchain suite is installed in the directory specified by CROSSTOOL_RELPATH.  As the name might
# suggest this path is relative to the home directory of the current user.
#
# Target:
#	Architecture: arm
#	Vendor: unknown
#	Operating System: linux
#	Environment: gnueabihf

CROSSTOOL_RELPATH=opt/crosstool
LOGFILE=$HOME/crosstool-config.log

source ${PWD}/utility.sh >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo -e "error: utility.sh missing"
	exit 1
fi

#if [ -z $GCC_LINK ] && [ -z $BINUTILS_LINK ]; then
#	abort "set GCC_LINK and BINUTILS_LINK to the download link of gcc and binutils respectively"
#elif [ -z $GCC_LINK ] && [ ! -z $BINUTILS_LINK ]; then
#	abort "set GCC_LINK to the download link of gcc"
#elif [ ! -z $GCC_LINK ] && [ -z $BINUTILS_LINK ]; then
#	abort "set BINUTILS_LINK to the download link of binutils"
#fi

#if [ -z $GLIBC_LINK ] && [ -z $NEWLIB_LINK ]; then
#	abort "set GLIBC_LINK or NEWLIB_LINK to the download link of eiter glibc or newlib"
#else if [ ! -z $GLIBC_LINK] && [ ! -z $NEWLIB_LINK ]; then
#	abort "GLIBC_LINK and NEWLIB_LINK cannot be set at the same time; choose one or the other"
#fi

	
#cd $HOME
#echo -e "retrieveing packages into ${HOME}"

#wget $GCC_LINK
#if [ $? -ne 0 ]; then
#	abort "${GCC_LINK} - gcc download failed"
#fi
#wget $BINUTILS_LINK
#if [ $? -ne 0 ]; then
#	abort "${BINUTILS_LINK} - binutils download failed"
#fi

#if [ ! -z $GLIBC_LINK ] && [ -z $NEWLIB_LINK ]; then
#	wget $GLIBC_LINK
#	if [ $? -ne 0 ]; then
#		abort "${GLIBC_LINK} - glibc download failed"
#	fi
#elif [ -z $GLIBC_LINK ] && [ ! -z $NEWLIB_LINK ]; then
#	wget $NEWLIB_LINK
#	if [ $? -ne 0 ]; then
#		abort "${NEWLIB_LINK} - newlib download failed"
#	fi
#fi

GCC_VERSION="4.9.2"
BINUTILS_VERSION="2.24"
GLIBC_VERSION="2.20"

if [ -z $HOST ]; then
	export HOST="x86_64-unknown-linux-gnu"
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
rm -f $LOGFILE
echo -e "cross-toolchain configuration log file\n" > $LOGFILE

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
	--with-sysroot=$SYSROOT --prefix=$PREFIX --with-lib-path=${PREFIX}/lib --disable-multilib \
	--disable-nls --disable-werror
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
	--prefix=$PREFIX --with-local-prefix=$PREFIX --with-native-system-header-dir=/usr/include \
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

sed -i "s#${PREFIX}\/lib\/libc.so.6#libc.so.6#g" ${PREFIX}/lib/libc.so
sed -i "s#${PREFIX}\/lib\/libc_nonshared.a#libc_nonshared.a#g" ${PREFIX}/lib/libc.so
sed -i "s#${PREFIX}\/lib\/ld-linux.so.3#ld-linux.so.3#g" ${PREFIX}/lib/libc.so

sed -i "s#${PREFIX}\/lib\/libpthread.so.0#libpthread.so.0#g" ${PREFIX}/lib/libpthread.so
sed -i "s#${PREFIX}\/lib\/libpthread_nonshared.a#libpthread_nonshared.a#g" ${PREFIX}/lib/libpthread.so


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# build and install gcc final
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "building gcc final and requisites for ${TARGET} with ${PREFIX} as the system root directory"
cd $HOME/build-gcc/build-gcc-final
if [ $? -eq 0 ]; then
	rm -rf *
fi
LDFLAGS="-Wl,-rpath,${PREFIX}/lib" ../../gcc-${GCC_VERSION}/configure --build=$HOST --host=$HOST \
	--target=$TARGET --with-sysroot=$SYSROOT --prefix=$PREFIX --with-local-prefix=$PREFIX \
	--with-native-system-header-dir=/usr/include --disable-static --disable-nls \
	--disable-multilib --enable-threads=posix --enable-languages=c,c++
make
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
