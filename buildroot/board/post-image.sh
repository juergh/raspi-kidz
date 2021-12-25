#!/bin/bash

set -u
set -e

#
# Create the updater initrd
#

initrd_dir="${BINARIES_DIR}"/initrd.d
rm -rf "${initrd_dir}"
mkdir "${initrd_dir}"

# Copy the init script
cp "${BR2_EXTERNAL_RASPI_KIDZ_PATH}"/board/init.sh  "${initrd_dir}"/init

# Install busybox
mkdir -p "${initrd_dir}"/bin
cp "${TARGET_DIR}"/bin/busybox "${initrd_dir}"/bin

# Install libc and ld
mkdir -p "${initrd_dir}"/lib
cp -dp "${TARGET_DIR}"/lib/libc.* "${TARGET_DIR}"/lib/libuClibc-* "${TARGET_DIR}"/lib/ld-* "${initrd_dir}"/lib
ln -s lib "${initrd_dir}"/lib32

# Create the initrd image
( cd "${initrd_dir}" && \
  find . | cpio -H newc -o | gzip -9 > "${BINARIES_DIR}"/initrd.img )
