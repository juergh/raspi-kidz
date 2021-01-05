#!/bin/make

BUILDD := $(PWD)/buildd

BR2_DIR := $(BUILDD)/buildroot
BR2_VERSION := 2020.11
BR2_EXTERNAL := $(PWD)/raspi_kidz
BR2_DEFCONFIG := raspi_kidz_defconfig
BR2_MAKE := BR2_EXTERNAL=$(BR2_EXTERNAL) $(MAKE) -C $(BR2_DIR)

KERNEL_VER := 5.4.y
KERNEL_CFG := DRM DRM_BOCHS SND_ENS1370

KERNEL_DIR := $(BUILDD)/linux-$(KERNEL_VER)
KERNEL_IMG := $(KERNEL_DIR)/arch/arm64/boot/Image

NUM_CPUS := $(shell getconf _NPROCESSORS_ONLN)
KMAKE := ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make

# ----------------------------------------------------------------------------
# Build targets

default:
	$(MAKE) defconfig
	$(MAKE) all

$(BR2_DIR):
	mkdir -p $(BR2_DIR)
	git clone --depth 1 --branch $(BR2_VERSION) \
	    git://git.buildroot.net/buildroot $(BR2_DIR)

defconfig: $(BR2_DIR)
	$(MAKE) $(BR2_DEFCONFIG)

deepclean:
	rm -rf $(BUILDD)

$(KERNEL_DIR)/Makefile:
	mkdir -p $(KERNEL_DIR)
	git clone --depth 1 --branch linux-$(KERNEL_VER) \
	    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
	    $(KERNEL_DIR)

$(KERNEL_IMG): $(KERNEL_DIR)/Makefile
	cd $(KERNEL_DIR) ; \
	$(KMAKE) defconfig ; \
	for cfg in $(KERNEL_CFG) ; do \
	    ./scripts/config -e $${cfg} ; \
	done ; \
	$(KMAKE) olddefconfig ; \
	for cfg in $(KERNEL_CFG) ; do \
	    grep "CONFIG_$${cfg}=y" .config || \
	        ( echo "Error: $${cfg} is not enabled" ; false ) ; \
	done ; \
	$(KMAKE) -j$(NUM_CPUS) Image

qemu: $(KERNEL_IMG)
	./qemu-raspi --mem 512 --smp 4 $(KERNEL_IMG) \
	    $(BR2_DIR)/output/images/sdcard.img

# ----------------------------------------------------------------------------
# Buildroot targets

all: WIFI_SSID ?= $(shell pass show local/wifi | grep '^ssid: ' | sed 's/^ssid: //')
all: WIFI_PASS ?= $(shell pass show local/wifi | grep '^passphrase: ' | sed 's/^passphrase: //')
all:
	@WIFI_SSID="$(WIFI_SSID)" WIFI_PASS="$(WIFI_PASS)" $(BR2_MAKE) all
	rm -f $(BR2_DIR)/output/target/etc/wpa_supplicant.conf

menuconfig:
	$(MAKE) defconfig
	$(BR2_MAKE) menuconfig
	$(MAKE) savedefconfig

%:
	$(BR2_MAKE) $@

.PHONY: default defconfig deepclean qemu all menuconfig
