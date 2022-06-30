#!/bin/busybox sh
#
# Installer init
#

#!/bin/busybox sh

rescue()
{
	echo "-- Drop into a rescue shell"
	/bin/sh
}

/bin/busybox --install /bin

set -e
trap rescue EXIT

[ -d /dev ] || mkdir -m 0755 /dev
[ -d /sys ] || mkdir /sys
[ -d /proc ] || mkdir /proc
mount -t devtmpfs devtmpfs /dev
mount -t sysfs sysfs /sys
mount -t proc proc /proc

if grep -q rescue /proc/cmdline ; then
	rescue
	reboot -f
fi

echo "-- Wait for root device"
root_dev=
while [ -z "${root_dev}" ] ; do
	sleep 1
	if [ -b /dev/mmcblk0 ] ; then
		# Raspberry Pi
		root_dev=/dev/mmcblk0
		first_part=/dev/mmcblk0p1
		stor_part=/dev/mmcblk0p3
	elif [ -b /dev/sda ] ; then
		# PC
		root_dev=/dev/sda
		first_part=/dev/sda1
		stor_part=/dev/sda2
	elif [ -b /dev/vda ] ; then
		# Raspberry Pi in QEMU
		root_dev=/dev/vda
		first_part=/dev/vda1
		stor_part=/dev/vda3
	fi
done

[ -d /storage ] || mkdir /storage
sleep 2
mount "${stor_part}" /storage
sleep 2

echo "-- Flash image"
start=$(cat /sys/class/block/"${first_part##*/}"/start)
dd conv=fsync bs=512 seek=${start} skip=${start} if=/storage/image.img \
   of="${root_dev}"
rm -f /storage/image.img

umount /storage
sync

echo "-- Reboot"
sleep 1
reboot -f
