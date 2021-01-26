#!/bin/bash

set -u
set -e

#
# Create /boot/cmdline.txt
#

conf=${BINARIES_DIR}/rpi-firmware/cmdline.txt
cat << __EOF__ > "${conf}"
root=/dev/mmcblk0p2 rootwait console=ttyS0,115200 vt.global_cursor_default=0 init=/sbin/overlay-init
__EOF__

#
# Fixup /boot/config.txt
#

conf=${BINARIES_DIR}/rpi-firmware/config.txt
sed -i '/^# RASPI-KIDZ/,$d' "${conf}"
cat << __EOF__ >> "${conf}"
# RASPI-KIDZ

# Enable audio
dtparam=audio=on

# Enable the serial console
enable_uart=1

# Configure the display
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
hdmi_drive=1

# Enable the touchscreen
dtparam=ic2_arm=on
dtparam=spi=on
dtoverlay=ads7846,cs=1,penirq=25,penirq_pull=2,speed=50000,keep_vref_on=0,swapxy=0,pmax=255,xohms=150,xmin=200,xmax=3900,ymin=200,ymax=3900
__EOF__

#
# Create the updater initrd
#

initrd_dir=$(mktemp -d)

# Create /init
cat <<EOF > "${initrd_dir}"/init
#!/bin/busybox sh

/bin/busybox --install /bin

[ -d /dev ] || mkdir -m 0755 /dev
mount -t devtmpfs devtmpfs /dev

[ -d /storage ] || mkdir /storage
mount /dev/mmcblk0p3 /storage
dd conv=fsync bs=512 if=/storage/boot.img of=/dev/mmcblk0p1
dd conv=fsync bs=512 if=/storage/root.img of=/dev/mmcblk0p2
umount /storage

sync
reboot -f
EOF
chmod 755 "${initrd_dir}"/init

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

# Cleanup
rm -rf "${initrd_dir}"

#
# Generate the image (copied from buildroot/board/raspberrypi3/post-image.sh)
#

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
