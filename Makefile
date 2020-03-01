#!/bin/make

BUILDD := $(PWD)/buildd

BR2_DIR := $(BUILDD)/buildroot
BR2_VERSION := 2019.11
BR2_EXTERNAL := $(PWD)/raspi_kidz
BR2_DEFCONFIG := raspi_kidz_defconfig

KERNEL_VER := 5.4.y
KERNEL_CFG := DRM DRM_BOCHS SND_ENS1370

KERNEL_DIR := $(BUILDD)/linux-$(KERNEL_VER)
KERNEL_IMG := $(KERNEL_DIR)/arch/arm64/boot/Image

NUM_CPUS := $(shell getconf _NPROCESSORS_ONLN)
KMAKE := ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make

QEMU_DIR := $(BUILDD)/qemu
QEMU_BIN := $(QEMU_DIR)/aarch64-softmmu/qemu-system-aarch64

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

$(QEMU_DIR)/Makefile:
	mkdir -p $(QEMU_DIR)
	git clone --depth 1 --branch v4.2.0 \
	    git://git.qemu.org/qemu.git \
	    $(QEMU_DIR)

$(QEMU_BIN): $(QEMU_DIR)/Makefile
	cd $(QEMU_DIR) ; \
	./configure --target-list=aarch64-softmmu ; \
	make -j$(NUM_CPUS)

qemu: $(QEMU_BIN) $(KERNEL_IMG)
	./qemu-raspi -q $(QEMU_BIN) $(KERNEL_IMG) \
	    $(BR2_DIR)/output/images/sdcard.img

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
