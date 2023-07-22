#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u



OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}
# Fail out if dir was not created
if [[ ! -d ${OUTDIR} ]]; then
    exit 1
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # Clean the build (deep clean)
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    # Build the defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    # Build the kernel
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    # Are the next two built by all?
    # Skip modules install
    # make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

    # Build the device tree
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

rootfs_dir=${OUTDIR}/rootfs

# TODO: Create necessary base directories
mkdir -p \
    ${rootfs_dir}/bin \
    ${rootfs_dir}/dev \
    ${rootfs_dir}/etc \
    ${rootfs_dir}/lib \
    ${rootfs_dir}/lib64 \
    ${rootfs_dir}/proc \
    ${rootfs_dir}/sbin \
    ${rootfs_dir}/sys \
    ${rootfs_dir}/tmp \
    ${rootfs_dir}/usr/bin \
    ${rootfs_dir}/usr/lib \
    ${rootfs_dir}/usr/sbin \
    ${rootfs_dir}/var/log \
    ${rootfs_dir}/home


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    # how so my dude
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${rootfs_dir} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${rootfs_dir}/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${rootfs_dir}/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
# Find them in the sysroot of the cross compile tool chain
toolchain_sysroot=$(${CROSS_COMPILE}gcc -print-sysroot)
prg_intp_path=$(find ${toolchain_sysroot} -name ld-linux-aarch64.so.1)
lib_path1=$(find ${toolchain_sysroot} -name libm.so.6 )
lib_path2=$(find ${toolchain_sysroot} -name  libresolv.so.2)
lib_path3=$(find ${toolchain_sysroot} -name  libc.so.6)

cp ${prg_intp_path} ${rootfs_dir}/lib
cp ${lib_path1} ${rootfs_dir}/lib64 
cp ${lib_path2} ${rootfs_dir}/lib64
cp ${lib_path3} ${rootfs_dir}/lib64

# TODO: Make device nodes
sudo mknod -m 666 ${rootfs_dir}/dev/null c 1 3
sudo mknod -m 666 ${rootfs_dir}/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp ${FINDER_APP_DIR}/writer ${rootfs_dir}/home/
cp ${FINDER_APP_DIR}/finder.sh ${rootfs_dir}/home/
cp -r ${FINDER_APP_DIR}/conf/ ${rootfs_dir}/home/
cp ${FINDER_APP_DIR}/finder-test.sh ${rootfs_dir}/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${rootfs_dir}/home/

# TODO: Chown the root directory
sudo chown -R root:root ${rootfs_dir}

# TODO: Create initramfs.cpio.gz
# This is the ramdisk
cd ${rootfs_dir}
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio
