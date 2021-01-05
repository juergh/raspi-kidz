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
# Fixup /etc/fstab
#

#conf="${TARGET_DIR}"/etc/fstab
#sed -i -e '/^# \[post-build\]$/,/^# \[post-build\]$/d' "${conf}"
#cat << __EOF__ >> "${conf}"
## [post-build]
#/dev/mmcblk0p1   /boot   vfat   defaults   0   2
## [post-build]
#__EOF__

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
