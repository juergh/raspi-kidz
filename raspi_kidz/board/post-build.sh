#!/bin/sh

set -u
set -e

# Remove the console on tty1
if [ -e "${TARGET_DIR}"/etc/inittab ]; then
	sed -i 's/^tty1::/#[post-build] tty1::/' "${TARGET_DIR}"/etc/inittab
fi
