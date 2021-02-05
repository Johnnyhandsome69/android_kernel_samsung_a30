#!/bin/bash
#
# Custom build script for Eureka kernels by Chatur27 and Gabriel260 @Github - 2020
#
# Updated by arpio
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

KERNEL_SRC_DIR=$(pwd)
KERNEL_OUT_DIR=$KERNEL_SRC_DIR/.out

CORES=$(nproc --all)

DEFCONFIG=halium-a30_defconfig
BUILD_START=$(date +"%s")
BUILD_END=$(date +"%s")
ZIPNAME=Halium
#Functions
PRINT_OUT()
{
	echo -e "[$(date +%H:%M:%S)]" '\t'  $1
}

COPY_DEFCONFIG()
{
	read -r -p "Copy .config to defconfig? [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
    cp -rf $KERNEL_OUT_DIR/.config $KERNEL_SRC_DIR/arch/arm64/configs/$DEFCONFIG

    ;;
        [nN][oO]|[nN])
		PRINT_OUT " "
    	;;
        *)
    PRINT_OUT "Invalid input..."
    ;;
    esac
}

ADD_VERSION()
{
# Enter kernel revision for this build.
	read -p "Please type kernel version : " rev;
	if [ "${rev}" == "" ]; then
		echo " "
		echo "     Using '$REV' as version"
	else
		REV=$rev
		echo " "
		echo "     Version = $REV"
	fi
	sleep 2

	VERSION="v"$REV
	ZIPNAME=$ZIPNAME"_"$REV".zip"
	export LOCALVERSION=_$VERSION
}

PRINT_BUILD_TIME(){
	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
	if [ $1 !=0 ]; then
		echo -e "\e[1;41m \e[1;97m ***Build failed*** \e[0m"
		echo -e "\e[1;41m \e[1;97m Total build time:   $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds \e[0m \e[0m"
	else
		echo -e "\e[1;42m \e[1;97m ***Build completed*** \e[0m"
		echo -e "\e[1;42m \e[1;97m Total build time:   $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds \e[0m \e[0m"
	fi
	COPY_DEFCONFIG
	exit
}

CREATE_ZIP(){
	PRINT_OUT "Create ZIP file to flash in TWRP"
	
	rsync -Pa $KERNEL_SRC_DIR/flashZip $KERNEL_OUT_DIR/
	rsync -Pa $KERNEL_OUT_DIR/arch/arm64/boot/Image $KERNEL_OUT_DIR/flashZip/anykernel/
	rsync -Pa $KERNEL_OUT_DIR/arch/arm64/boot/dtbo.img $KERNEL_OUT_DIR/flashZip/anykernel/

	rsync -Pa $(dirname $(dirname $(realpath $0)) )/rootfs.img $KERNEL_OUT_DIR/flashZip/anykernel/ubports/
	rsync -Pa $(dirname $(dirname $(realpath $0)) )/system.img $KERNEL_OUT_DIR/flashZip/anykernel/ubports/

	cd $KERNEL_OUT_DIR/flashZip/anykernel
	7z a $ZIPNAME *
	chmod 0777 $ZIPNAME
	cd $KERNEL_SRC_DIR
	sleep 1
}

EXPORT_VARS()
{
	export ARCH=arm64
	export CROSS_COMPILE=$(dirname $(dirname $(realpath $0)) )/toolchain/bin/aarch64-linux-gnu-
	export KBUILD_BUILD_USER=arpio
	export KBUILD_BUILD_HOST=workstation
}

BUILD_KERNEL()
{
	clear
	PRINT_OUT "Starting build process..."
	BUILD_START=$(date +"%s")
	make O=$KERNEL_OUT_DIR $DEFCONFIG

	read -r -p "Run xconfig before build? [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
    make xconfig O=$KERNEL_OUT_DIR
    COPY_DEFCONFIG
    BUILD_START=$(date +"%s")
    make -j$CORES O=$KERNEL_OUT_DIR
    BUILD_STATE=$?
	CREATE_ZIP
	PRINT_BUILD_TIME $BUILD_STATE
    ;;
        [nN][oO]|[nN])
	BUILD_START=$(date +"%s")
	make -j$CORES O=$KERNEL_OUT_DIR
	BUILD_STATE=$?
	CREATE_ZIP
	PRINT_BUILD_TIME $BUILD_STATE
    	;;
        *)
    PRINT_OUT "Invalid input..."
    ;;
    esac
}

REBUILD_KERNEL()
{
	clear
	PRINT_OUT "Rebuilding Kernel..."
	BUILD_START=$(date +"%s")
	make -j$CORES O=$KERNEL_OUT_DIR
	BUILD_STATE=$?
	CREATE_ZIP
	PRINT_BUILD_TIME $BUILD_STATE
}

SELECT_BUILD_TYPE()
{
	echo "************************************";
	echo "	Select option                     ";
	echo "************************************";
	echo " "
	echo "  1. Clean build";
	echo " "
	echo "  2. Rebuild after errors";
	echo " "
	echo "  3. Run xconfig";
	echo " "
	echo "  4. Clean source tree";
	echo " "
	read -n 1 -p "Please select: " -s build;
	echo -e '\n'
	case ${build} in
		1)
		   {
				if [ -d $KERNEL_OUT_DIR ]; then
			        PRINT_OUT "Removing build directory: $KERNEL_OUT_DIR"
			        rm -r $KERNEL_OUT_DIR
			        sleep 1
			        PRINT_OUT "Creating new build firectory: $KERNEL_OUT_DIR"
			        mkdir $KERNEL_OUT_DIR
			    else
			        PRINT_OUT "Creating build directory: $KERNEL_OUT_DIR"
			        mkdir $KERNEL_OUT_DIR
			    fi

			    BUILD_KERNEL
		   };;
		2)
		   {
			   	if [ -d $KERNEL_OUT_DIR ]; then
				        REBUILD_KERNEL
				    else
				        PRINT_OUT "Build directory does not exist: $KERNEL_OUT_DIR"
				        exit
				fi
		   };;

		3)
		   {
			   	if [ -d $KERNEL_OUT_DIR ]; then
				    PRINT_OUT "Removing build directory: $KERNEL_OUT_DIR"
				    rm -r $KERNEL_OUT_DIR
				    sleep 1
				    PRINT_OUT "Creating new build firectory: $KERNEL_OUT_DIR"
				    mkdir $KERNEL_OUT_DIR

				    make O=$KERNEL_OUT_DIR $DEFCONFIG
				    make xconfig O=$KERNEL_OUT_DIR $DEFCONFIG
				else
				    PRINT_OUT "Creating build directory: $KERNEL_OUT_DIR"
				    mkdir $KERNEL_OUT_DIR

				    make O=$KERNEL_OUT_DIR $DEFCONFIG
				    make xconfig O=$KERNEL_OUT_DIR $DEFCONFIG
				fi
		   };;

		4)
		   {
			   	make clean
			   	make mrproper
		   };;
		*)
		   {
			PRINT_OUT "Invalid option. Exiting..."
			sleep 2
			exit 1
		   };;
	esac
}

#Start script
EXPORT_VARS

ADD_VERSION

SELECT_BUILD_TYPE
