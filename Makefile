#!/bin/make

BOARD ?= raspi-kidz

BUILDD := $(PWD)/buildd/$(BOARD)

BR2_DIR := $(BUILDD)/buildroot
BR2_VERSION := 2021.08.3
BR2_EXTERNAL := $(PWD)/buildroot
BR2_CONFIG := $(BR2_EXTERNAL)/configs/$(BOARD).config
BR2_MAKE := BR2_EXTERNAL=$(BR2_EXTERNAL) $(MAKE) -C $(BR2_DIR)

ifeq ($(BOARD),raspi-kidz)
  BR_KERNEL := linux-custom
else
  BR_KERNEL := linux-4.19.222
endif

KERNEL_VER := 5.4.y
KERNEL_CFG := DRM DRM_BOCHS SND_ENS1370 OVERLAY_FS

KERNEL_DIR := $(BUILDD)/linux-$(KERNEL_VER)
KERNEL_IMG := $(KERNEL_DIR)/arch/arm64/boot/Image

NUM_CPUS := $(shell getconf _NPROCESSORS_ONLN)
KMAKE := ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make

ifeq ($(wildcard $(BR2_CONFIG)),)
  $(error "Invalid version: $(BOARD)")
endif

# ----------------------------------------------------------------------------
# Build targets

default: config all

$(BR2_DIR):
	mkdir -p $(BR2_DIR)
	git clone --depth 1 --branch $(BR2_VERSION) \
	    git://git.buildroot.net/buildroot $(BR2_DIR)

config: $(BR2_DIR)
	cp $(BR2_CONFIG) $(BR2_DIR)/.config

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
	./qemu-pc --mem 4096 --smp 4 $(BR2_DIR)/output/images/disk.img

qemu-raspi-kidz: $(KERNEL_IMG)
	./qemu-raspi --mem 512 --smp 4 $(KERNEL_IMG) \
	    $(BR2_DIR)/output/images/sdcard.img

qemu-initrd: $(KERNEL_IMG)
	./qemu-raspi --initrd $(BR2_DIR)/output/images/initrd.img --mem 512 \
	    --smp 4 $(KERNEL_IMG) $(BR2_DIR)/output/images/sdcard.img

# ----------------------------------------------------------------------------
# Buildroot targets

all: WIFI_SSID ?= $(shell pass show local/wifi | sed -n 's/^ssid: //p')
all: WIFI_PASS ?= $(shell pass show local/wifi | sed -n 's/^passphrase: //p')
all:
	@WIFI_SSID="$(WIFI_SSID)" WIFI_PASS="$(WIFI_PASS)" $(BR2_MAKE) all
	rm -f $(BR2_DIR)/output/target/etc/wpa_supplicant.conf

menuconfig: config
	$(BR2_MAKE) menuconfig
	cp  $(BR2_DIR)/.config $(BR2_CONFIG)

linux-menuconfig: $(BR2_DIR)
	$(BR2_MAKE) linux-menuconfig
	cp $(BR2_DIR)/output/build/$(BR_KERNEL)/.config \
	   $(BR2_EXTERNAL)/board/$(BOARD)/linux.config

%:
	$(BR2_MAKE) $@

.PHONY: default defconfig deepclean qemu all menuconfig
