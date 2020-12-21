FAMILY = pic14
DEVICE = 16f88
PIC = PIC16F88

SDCC ?= $(HOME)/Projects/tools/sdcc-3.9.0/bin/sdcc
CC = $(SDCC)
CFLAGS = --use-non-free -m$(FAMILY) -p$(DEVICE)

PK2CMD ?= $(HOME)/Projects/tools/pk2cmd/bin/pk2cmd
DO_PK2CMD = cd "$(dir $(PK2CMD))" && sudo "$(PK2CMD)"

all: raspi-kidz.hex

%.hex: %.c
	$(CC) $(CFLAGS) $<

clean:
	rm -f *.asm *.cod *.hex *.lst *.o

detect:
	$(DO_PK2CMD) -P

erase:
	$(DO_PK2CMD) -P$(PIC) -E

program: raspi-kidz.hex
	$(DO_PK2CMD) -P$(PIC) -F$(PWD)/$< -M
