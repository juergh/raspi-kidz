#!/bin/sh

set -u
set -e

#
# Fixup /etc/initab
#

# Clear any gettys and put a login on /dev/console
conf="${TARGET_DIR}"/etc/inittab
sed -i '/::respawn:/d' "${conf}"
cat << __EOF__ >> "${conf}"
::respawn:/bin/login -f admin
__EOF__

#
# Generate /etc/wpa_supplicant.conf
#

if [ -n "${WIFI_SSID}" ] && [ -n "${WIFI_PASS}" ] ; then
	conf="${TARGET_DIR}"/etc/wpa_supplicant.conf
	cat << EOF > "${conf}"
update_config=1
country=CH
EOF
	wpa_passphrase "${WIFI_SSID}" "${WIFI_PASS}" | sed '/#psk/d' >> "${conf}"
fi

#
# Pre-generate SSH host keys
#

ssh-keygen -A -f "${TARGET_DIR}"

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
cp -dp "${TARGET_DIR}"/lib/libc.* "${TARGET_DIR}"/lib/libuClibc-* "${TARGET_DIR}"/lib/ld* "${initrd_dir}"/lib
ln -s lib "${initrd_dir}"/lib32

# Create the initrd image
( cd "${initrd_dir}" && \
  find . | cpio -H newc -o | gzip -9 > "${BINARIES_DIR}"/initrd.img )

# Copy the initrd if necessary
if [ -e "${TARGET_DIR}"/boot/bzImage ] ; then
	cp "${BINARIES_DIR}"/initrd.img "${TARGET_DIR}"/boot
fi

#
# Fix grub
#

if [ -d "${TARGET_DIR}"/boot/grub ] ; then
	# Use our own version of grub.cfg
	cat <<EOF >"${TARGET_DIR}"/boot/grub/grub.cfg
set default="0"
set timeout="2"

menuentry "PC-Kidz" {
        linux  /boot/bzImage root=/dev/sda1 rootwait net.ifnames=0 console=ttyS0
}

menuentry "PC-Kidz Update" {
        linux  /boot/bzImage
        initrd /boot/initrd.img
}

menuentry "PC-Kidz Rescue" {
        linux  /boot/bzImage root=/dev/sda1 rootwait net.ifnames=0 noqplayer
}
EOF

	 # Copy grub 1st stage to binaries, required for genimage
	cp -f "${HOST_DIR}"/lib/grub/i386-pc/boot.img "${BINARIES_DIR}"
fi
