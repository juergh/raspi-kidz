#!/bin/make

BUILDD := $(PWD)/buildd

BR2_DIR := $(BUILDD)/buildroot
BR2_VERSION := 2019.11
BR2_EXTERNAL := $(PWD)/raspi_kidz
BR2_DEFCONFIG := raspi_kidz_defconfig

KERNEL_DIR := $(BUILDD)/linux
KERNEL := $(KERNEL_DIR)/arch/arm64/boot/Image

NUM_CPUS := $(shell getconf _NPROCESSORS_ONLN)
KMAKE := ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make

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
	git clone --depth 1 --branch linux-4.19.y \
	    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
	    $(KERNEL_DIR)

$(KERNEL): $(KERNEL_DIR)/Makefile
	cd $(KERNEL_DIR) ; \
	$(KMAKE) defconfig ; \
	./scripts/config -e DRM -e DRM_BOCHS ; \
	$(KMAKE) olddefconfig ; \
	grep 'CONFG_DRM_BOCHS=y' .config || \
	  ( echo "Error: DRM_BOCHS is not enabled" ; false ) ; \
	$(KMAKE) -j$(NUM_CPUS) Image

qemu: $(KERNEL)
	./qemu-raspi $(KERNEL) $(BR2_DIR)/output/images/sdcard.img

# Generic buildroot rules
%:
	if [ "$@" = "menuconfig" ] ; then \
	    $(MAKE) defconfig ; \
	fi
	BR2_EXTERNAL=$(BR2_EXTERNAL) $(MAKE) -C $(BR2_DIR) $@
	if [ "$@" = "menuconfig" ] ; then \
	    $(MAKE) savedefconfig ; \
	fi

.PHONY: default defconfig deepclean qemu
