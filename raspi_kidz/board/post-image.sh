#!/bin/bash

set -e

cat << __EOF__ > "${BINARIES_DIR}"/rpi-firmware/cmdline.txt
root=/dev/mmcblk0p2 rootwait console=ttyAMA0,115200 logo.nologo vt.global_cursor_default=0
__EOF__

cat << __EOF__ >> "${BINARIES_DIR}"/rpi-firmware/config.txt
enable_uart=1
__EOF__
