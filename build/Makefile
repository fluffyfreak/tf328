BOARD:=tf328
RAMSOURCES="../rtl/ramcpld.v ../rtl/gayle.v ../rtl/fastmem.v"
MUXSOURCES="../rtl/muxcpld.v"

all: ram mux
ram: clean
	make -f Makefile.cpld BOARD=$(BOARD) PART=XC9572XL-10-VQ64 SOURCES=$(RAMSOURCES) PROJECT=ramcpld SUBPROJ=bus REVISION=rev1 OPTIMISE=speed
mux: clean
	make -f Makefile.cpld BOARD=$(BOARD) PART=XC9536XL-10-VQ44 SOURCES=$(MUXSOURCES) PROJECT=muxcpld SUBPROJ=mux REVISION=rev1 OPTIMISE=speed
clean:	
	rm -rf work _xmsgs
distclean: clean
	rm -f *.jed *~ *.svf