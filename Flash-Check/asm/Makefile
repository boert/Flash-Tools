#all: MODUL.BIN

flashcheck.kcc: flashcheck.bin
		mv flashcheck.bin flashcheck.kcc

flashcheck.bin: flashcheck.asm datetime.inc date.inc
		pasmo -v flashcheck.asm flashcheck.bin flashcheck.symbol


datetime.inc: FORCE
		@echo -n "BUILDSTR DB 'build: "      >  datetime.inc
		@echo -n `date +"%d.%m.%y %H:%M"`    >> datetime.inc
		@echo -n "', 0"                      >> datetime.inc

date.inc: FORCE
		@echo -n "BUILDSTR DB          '"    >  date.inc
		@echo -n `date +"%d.%m.%Y"`          >> date.inc
		@echo -n "', 0"                      >> date.inc

FORCE:

clean:
		rm -f flashcheck.bin
		rm -f flashcheck.symbol
		rm -f datetime.inc
		rm -f date.inc

		# dummy file for testing
dummy_ff.bin:
		dd if=/dev/zero ibs=1k count=8 | tr "\000" "\377" > dummy_ff.bin

		# calculate checksum
check_dummy: dummy_ff.bin
		jacksum -a crc:16,1021,ffff,false,false,0   -X  dummy_ff.bin
