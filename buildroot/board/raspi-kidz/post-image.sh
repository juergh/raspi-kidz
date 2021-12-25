#!/bin/bash

set -u
set -e

#
# Create /boot/cmdline.txt
#

conf=${BINARIES_DIR}/rpi-firmware/cmdline.txt
cat << __EOF__ > "${conf}"
root=/dev/mmcblk0p2 rootwait console=ttyS0,115200 logo.nologo vt.global_cursor_default=0 init=/sbin/overlay-init
__EOF__
#

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

# Disable the PWR LED
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off

# Disable the Activity LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
__EOF__
