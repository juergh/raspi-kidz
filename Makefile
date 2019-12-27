#!/bin/make

BR2_VERSION := 2019.11

all: buildd/Makefile
	cp raspi-kidz.config buildd/.config
	$(MAKE) -C buildd

clean: buildd/Makefile
	$(MAKE) -C buildd clean

deepclean:
	rm -rf buildd

buildd/Makefile:
	git clone --depth 1 --branch $(BR2_VERSION) \
	    git://git.buildroot.net/buildroot buildd
