#all: MODUL.BIN

romcheck.kcc: romcheck.bin
		mv romcheck.bin romcheck.kcc

romcheck.bin: romcheck.asm datetime.inc date.inc
		#pasmo -v romcheck.asm romcheck.bin romcheck.symbol
		z80asm --list=romcheck.lst --output romcheck.bin  $<


.PHONY: datetime.inc
datetime.inc:
		@echo -n "BUILDSTR:DB 'build: "      >  datetime.inc
		@echo -n `date +"%d.%m.%y %H:%M"`    >> datetime.inc
		@echo -n "', 0"                      >> datetime.inc

.PHONY: date.inc
date.inc:
		@echo -n "BUILDSTR:DB          '"    >  date.inc
		@echo -n `date +"%d.%m.%Y"`          >> date.inc
		@echo -n "', 0"                      >> date.inc

clean:
		rm -f romcheck.bin
		rm -f romcheck.symbol
		rm -f datetime.inc
		rm -f date.inc

		# dummy file for testing
dummy_ff.bin:
		dd if=/dev/zero ibs=1k count=8 | tr "\000" "\377" > dummy_ff.bin

		# calculate checksum
check_dummy: dummy_ff.bin
		jacksum -a crc:16,1021,ffff,false,false,0   -X  dummy_ff.bin
