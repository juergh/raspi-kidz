#!/bin/sh

set -e

# Remove all console and tty1 lines
sed -i -e '/^console::/d' -e '/^tty1::/d' "${TARGET_DIR}"/etc/inittab

# Remove everything after '# [post-build]'
sed -i -e '/^# \[post-build\]$/,$d' "${TARGET_DIR}"/etc/inittab

# Add getty/login to the serial and HDMI consoles
cat << __EOF__ >> "${TARGET_DIR}"/etc/inittab
# [post-build]
# tty1::respawn:/sbin/getty -L tty1 0 vt100 # HDMI console
console::respawn:/bin/login -f admin
__EOF__
