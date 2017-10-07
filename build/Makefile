BOARD:=tf328
BUSSOURCES="../rtl/ramcpld.v ../rtl/gayle.v ../rtl/fastmem.v"
RAMSOURCES="../rtl/muxcpld.v"

all: ram
ram: clean
	make -f Makefile.cpld BOARD=$(BOARD) SOURCES=$(BUSSOURCES) PROJECT=ramcpld SUBPROJ=bus REVISION=rev1 OPTIMISE=speed
clean:	
	rm -rf work _xmsgs
distclean: clean
	rm -f *.jed *~ *.svf