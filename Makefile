#!/bin/make

BR2_VERSION := 2019.11

all: buildd/Makefile
	cp raspi-kidz.config buildd/.config
	$(MAKE) -C buildd

buildd/Makefile:
	git clone -b $(BR2_VERSION) git://git.buildroot.net/buildroot buildd
