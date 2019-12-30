#!/bin/make

BUILDD := buildd

BR2_DIR := $(BUILDD)/buildroot
BR2_VERSION := 2019.11
BR2_EXTERNAL := raspi_kidz
BR2_DEFCONFIG := raspi_kidz_defconfig
BR2_MAKE := BR2_EXTERNAL=../../$(BR2_EXTERNAL) $(MAKE) -C $(BR2_DIR)

default:
	$(MAKE) $(BR2_DEFCONFIG)
	$(MAKE) all

$(BR2_DIR):
	mkdir -p $(BR2_DIR)
	git clone --depth 1 --branch $(BR2_VERSION) \
	    git://git.buildroot.net/buildroot $(BR2_DIR)

qemu:
	./qemu-raspi $(BR2_DIR)/output/images/sdcard.img

deepclean:
	rm -rf $(BUILDD)

$(BR2_DEFCONFIG) clean: $(BR2_DIR)
	$(BR2_MAKE) $@

all menuconfig: $(BR2_DEFCONFIG)
	$(BR2_MAKE) $@
	if [ "$@" = "menuconfig" ] ; then \
	    cp $(BR2_DIR)/.config $(BR2_EXTERNAL)/configs/$(BR2_DEFCONFIG) ; \
	    sed -i 's,$(PWD),../..,' $(BR2_EXTERNAL)/configs/$(BR2_DEFCONFIG) ; \
	fi
