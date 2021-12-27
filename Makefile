#!/bin/make

BOARD ?= raspi-kidz

BUILDD := $(PWD)/buildd/$(BOARD)

BR_DIR := $(BUILDD)/buildroot
BR_VERSION := 2021.08.3
BR_EXTERNAL := $(PWD)/buildroot
BR_CONFIG := $(BR_EXTERNAL)/configs/$(BOARD).config
BR_MAKE := BR2_EXTERNAL=$(BR_EXTERNAL) $(MAKE) -C $(BR_DIR)

ifeq ($(BOARD),raspi-kidz)
  BR_KERNEL := linux-custom
else
  BR_KERNEL := linux-5.10.88
endif

ifeq ($(wildcard $(BR_CONFIG)),)
  $(error "Invalid board: $(BOARD)")
endif

# QEMU related variables

KERNEL_VER := 5.4.y
KERNEL_CFG := DRM DRM_BOCHS SND_ENS1370 OVERLAY_FS

KERNEL_DIR := $(BUILDD)/linux-$(KERNEL_VER)
KERNEL_IMG := $(KERNEL_DIR)/arch/arm64/boot/Image

NUM_CPUS := $(shell getconf _NPROCESSORS_ONLN)
KMAKE := ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make

# ----------------------------------------------------------------------------
# Build targets

default: config all

$(BR_DIR):
	mkdir -p $(BR_DIR)
	git clone --depth 1 --branch $(BR_VERSION) \
	    git://git.buildroot.net/buildroot $(BR_DIR)

config: $(BR_DIR)
	cp $(BR_CONFIG) $(BR_DIR)/.config

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

qemu: qemu-$(BOARD)

qemu-pc-kidz:
	./qemu-pc --mem 4096 --smp 4 $(BR_DIR)/output/images/disk.img

qemu-raspi-kidz: $(KERNEL_IMG)
	./qemu-raspi --mem 512 --smp 4 $(KERNEL_IMG) \
	    $(BR_DIR)/output/images/sdcard.img

qemu-initrd: $(KERNEL_IMG)
	./qemu-raspi --initrd $(BR_DIR)/output/images/initrd.img --mem 512 \
	    --smp 4 $(KERNEL_IMG) $(BR_DIR)/output/images/sdcard.img

# ----------------------------------------------------------------------------
# Buildroot targets

all: WIFI_SSID ?= $(shell pass show local/wifi | sed -n 's/^ssid: //p')
all: WIFI_PASS ?= $(shell pass show local/wifi | sed -n 's/^passphrase: //p')
all:
	@WIFI_SSID="$(WIFI_SSID)" WIFI_PASS="$(WIFI_PASS)" $(BR_MAKE) all
	rm -f $(BR_DIR)/output/target/etc/wpa_supplicant.conf

menuconfig: config
	$(BR_MAKE) menuconfig
	cp  $(BR_DIR)/.config $(BR_CONFIG)

linux-menuconfig: $(BR_DIR)
	$(BR_MAKE) linux-menuconfig
	cp $(BR_DIR)/output/build/$(BR_KERNEL)/.config \
	   $(BR_EXTERNAL)/board/$(BOARD)/linux.config

%:
	$(BR_MAKE) $@

.PHONY: default defconfig deepclean qemu all menuconfig
