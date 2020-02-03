#!/bin/make

BUILDD := $(PWD)/buildd

BR2_DIR := $(BUILDD)/buildroot
BR2_VERSION := 2019.11
BR2_EXTERNAL := $(PWD)/raspi_kidz
BR2_DEFCONFIG := raspi_kidz_defconfig

FW_DIR := $(BUILDD)/firmware

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

$(FW_DIR):
	mkdir -p $(FW_DIR)
	git clone --depth 1 --branch master \
	    git://github.com/raspberrypi/firmware $(FW_DIR)

qemu: $(FW_DIR)
	./qemu-raspi $(BR2_DIR)/output/images/sdcard.img

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
