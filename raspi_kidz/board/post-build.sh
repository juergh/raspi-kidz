#!/bin/sh

set -e

#
# Fixup /etc/initab
#

conf="${TARGET_DIR}"/etc/inittab
sed -i -e '/^console::/d' -e '/^tty1::/d' "${conf}"
sed -i -e '/^# \[post-build\]$/,/^# \[post-build\]$/d' "${conf}"
cat << __EOF__ >> "${conf}"
# [post-build]
# tty1::respawn:/sbin/getty -L tty1 0 vt100 # HDMI console
tty1::respawn:/bin/login -f admin
console::respawn:/bin/login -f admin
# [post-build]
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

conf="${TARGET_DIR}"/etc/wpa_supplicant.conf
cat << EOF > "${conf}"
# [post-build]
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=CH
EOF
ssid=$(pass show local/wifi | grep '^ssid: ' | sed 's/^ssid: //')
pass=$(pass show local/wifi | grep '^passphrase: ' | sed 's/^passphrase: //')
wpa_passphrase "${ssid}" "${pass}" | sed '/#psk/d' >> "${conf}"
