#!/usr/bin/bash
#
# File: arm-unknown-linux-gnueabihf.sh
# Created: 06, December 2014
#
# 
# Copyright (C) 2014 Jarielle Catbagan
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Synopsis:
#
# This script configures a cross-toolchain specifically targeting the target platform specified with the 
# parameters listed below.
#
# See ./README for further details.
#
# The toolchain suite is installed in the directory specified by CROSSTOOL_RELPATH.  As the name might
# suggest this path is relative to the home directory of the current user.
#
# Target:
#	Architecture: arm
#	Vendor: unknown
#	Operating System: linux
#	Environment: gnueabihf

# parse mandatory option (-n/--native or -c/--cross) before continuing
if [ $# -lt 1 ]; then
	echo -e "no option specified\n"
	echo -e "Usage: arm-unknown-linux-gnueabihf option"
	echo -e "\t-c --cross\tbuild the cross-toolchain to run on the target"
	echo -e "\t-n --native\tbuild the cross-toolchain to run on where it is built"
	exit 1
elif [ $# -gt 1 ]; then
	echo -e "too many arguments specified\n"
	echo -e "Usage: arm-unknown-linux-gnueabihf option"
	echo -e "\t-c --cross\tbuild the cross-toolchain to run on the target"
	echo -e "\t-n --native\tbuild the cross-toolchain to run on where it is built"
	exit 1
else
	case $1 in
	-n)
		BUILD_TYPE=native
		;;		
	--native)
		BUILD_TYPE=native
		;;
	--c)
		BUILD_TYPE=cross
		;;
	--cross)
		BUILD_TYPE=cross
		;;
	*)
		echo -e "invalid option specified\n"
		echo -e "Usage: arm-unknown-linux-gnueabihf option"
		echo -e "\t-c --cross\tbuild the cross-toolchain to run on the target"
		echo -e "\t-n --native\tbuild the cross-toolchain to run on where it is built"
		exit 1
	esac
fi

CROSSTOOL_RELPATH=opt/crosstool
LOGFILE=$HOME/crosstool-config.log

# HOST is set later by running the config.guess script in one of the packages downloaded if building
# a cross-toolchain that will run on the same platform that it is built on.  Otherwise it will be set 
# to TARGET for a toolchain that will run natively on the target.
export TARGET="arm-unknown-linux-gnueabihf"
export SYSROOT=${HOME}/${CROSSTOOL_RELPATH}
export PREFIX=${SYSROOT}/usr
# check if the location of the cross-toolchain os already in the path to prevent redefinition
echo $PATH | grep "${PREFIX}/bin" - 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	export PATH=$PREFIX/bin:$PATH
fi

GCC_LINK=http://ftp.gnu.org/gnu/gcc/gcc-4.9.2
GCC_FILE=gcc-4.9.2.tar.bz2
BINUTILS_LINK=http://ftp.gnu.org/gnu/binutils
BINUTILS_FILE=binutils-2.24.tar.bz2
GLIBC_LINK=http://ftp.gnu.org/gnu/glibc
GLIBC_FILE=glibc-2.20.tar.bz2
GMP_LINK=http://ftp.gnu.org/gnu/gmp
GMP_FILE=gmp-6.0.0a.tar.bz2
MPC_LINK=http://ftp.gnu.org/gnu/mpc
MPC_FILE=mpc-1.0.2.tar.gz
MPFR_LINK=http://ftp.gnu.org/gnu/mpfr
MPFR_FILE=mpfr-3.1.2.tar.bz2

# include functions from utility.sh
source ${PWD}/utility.sh >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo -e "error: utility.sh missing"
	exit 1
fi

cd $HOME
echo -e "retrieveing packages into ${HOME}"

# download all necessary packages
download $GCC_LINK $GCC_FILE
if [ $? -ne 0 ]; then
	abort "${GCC_LINK}/${GCC_FILE} - gcc download failed"
fi
download $BINUTILS_LINK $BINUTILS_FILE
if [ $? -ne 0 ]; then
	abort "${BINUTILS_LINK}/${BINUTILS_FILE} - binutils download failed"
fi
download $GLIBC_LINK $GLIBC_FILE
if [ $? -ne 0 ]; then
	abort "${GLIBC_LINK}/${GLIBC_FILE} - glibc download failed"
fi
download $GMP_LINK $GMP_FILE
if [ $? -ne 0 ]; then
	abort "${GMP_LINK}/${GMP_FILE} - gmp download failed"
fi
download $MPC_LINK $MPC_FILE
if [ $? -ne 0 ]; then
	abort "${MPC_LINK}/${MPC_FILE} - mpc download failed"
fi
download $MPFR_LINK $MPFR_FILE
if [ $? -ne 0 ]; then
	abort "${MPFR_LINK}/${MPFR_FILE} - mpfr download failed"
fi

extract GCC_FILE
echo $GCC_FILE
extract BINUTILS_FILE
echo $BINUTILS_FILE
extract GLIBC_FILE
echo $GLIBC_FILE
extract GMP_FILE
echo $GMP_FILE
extract MPC_FILE
echo $MPC_FILE
extract MPFR_FILE
echo $MPFR_FILE

export HOST=`${HOME}/${GCC_FILE}/config.guess`

# verify if the specified location for installing the final binaries exist
# if not make the appropriate directories, otherwise remove everything so we can start anew
cd $HOME
if [ ! -d $PREFIX ]; then
	mkdir -p $CROSSTOOL_RELPATH/usr
else
	cd $CROSSTOOL_RELPATH
	rm -rf *
	mkdir usr
fi

# install kernel headers
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

# let's start a clean slate, so remove and make the respective 'build' directories unconditionally
cd $HOME
rm -rf ${BINUTILS_FILE}-build ${GCC_FILE}-build ${GLIBC_FILE}-build
mkdir ${BINUTILS_FILE}-build ${GCC_FILE}-build ${GLIBC_FILE}-build
cd  ${GCC_FILE}-build
if [ $? -eq 0 ]; then
	mkdir ${GCC_FILE}-pre-build ${GCC_FILE}-final-build
fi

# set the symlinks in the main gcc directory from the gcc package to the necessary libraries previously 
# obtained in order to build gcc
cd $HOME
cd $GCC_FILE
ln -s ${HOME}/${GMP_FILE} gmp
ln -s ${HOME}/${MPC_FILE} mpc
ln -s ${HOME}/${MPFR_FILE} mpfr



# build and install binutils
log "building binutils for ${TARGET}"
cd ${HOME}/${BINUTILS_FILE}-build
../${BINUTILS_FILE}/configure --build=$HOST --host=$HOST --target=$TARGET \
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


# build and install gcc stage-1
log "building gcc stage-1 for ${TARGET} with ${PREFIX} as the system root directory"
cd ${HOME}/${GCC_FILE}-build/${GCC_FILE}-pre-build
../../${GCC_FILE}/configure --build=$HOST --host=$HOST --target=$TARGET --with-sysroot=$SYSROOT \
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


# build and install glibc
log "building glibc for ${TARGET}"
cd ${HOME}/${GLIBC_FILE}-build
CC="${TARGET}-gcc" AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" ../${GLIBC_FILE}/configure \
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


# build and install gcc final
log "building gcc final and requisites for ${TARGET} with ${PREFIX} as the system root directory"
cd ${HOME}/${GCC_FILE}-build/${GCC_FILE}-final-build
LDFLAGS="-Wl,-rpath,${PREFIX}/lib" ../../${GCC_FILE}/configure --build=$HOST --host=$HOST \
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
