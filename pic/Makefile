FAMILY = pic14
DEVICE = 16f88

CC = sdcc
CFLAGS = --use-non-free -m$(FAMILY) -p$(DEVICE)

PK2CMD ?= ~/Projects/tools/pk2cmd/bin/pk2cmd

#SDCC_DIR = /usr/local/share/sdcc

#LD = gplink
#LDFLAGS = --use-shared --processor-mismatch --map \
#	$(SDCC_DIR)/non-free/lib/$(FAMILY)/$(DEVICE).lib \
#	$(SDCC_DIR)/lib/$(FAMILY)/libsdcc.lib

all: raspi-kidz.hex

%.hex: %.c
	$(CC) $(CFLAGS) $<

clean:
	rm -f *.asm *.cod *.hex *.lst *.o

detect:
	$(PK2CMD) -P
