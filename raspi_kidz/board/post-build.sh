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
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
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
# Fix grub
#

if [ -d "${TARGET_DIR}"/boot/grub ] ; then
	# Use our own version of grub.cfg
	cat <<EOF >"${TARGET_DIR}"/boot/grub/grub.cfg
set default="0"
set timeout="2"

menuentry "Buildroot" {
        linux /boot/bzImage root=/dev/sda1 rootwait console=ttyS0
}
EOF

	 # Copy grub 1st stage to binaries, required for genimage
    cp -f "${HOST_DIR}"/lib/grub/i386-pc/boot.img "${BINARIES_DIR}"

fi
