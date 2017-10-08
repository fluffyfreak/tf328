.PHONY: clean read_cycle write_cycle
SUPPORT:=../rtl/
RTLFOLDER:=../../rtl
RAMFOLDER:=$(RTLFOLDER)/
RAMCPLD:=$(RAMFOLDER)/ramcpld.v $(RTLFOLDER)/fastmem.v $(RTLFOLDER)/gayle.v 
IV:=iverilog
TARGETS:=read_cycle write_cycle
all: $(TARGETS)
read_cycle:
	$(IV)  $(@).v $(RAMCPLD) $(SUPPORT)/FDCPE.v $(SUPPORT)/FDCP.v $(SUPPORT)/PULLUP.v -o $(@)
	./$(@)
write_cycle:
	$(IV)  $(@).v $(RAMCPLD) $(SUPPORT)/FDCPE.v $(SUPPORT)/FDCP.v $(SUPPORT)/PULLUP.v -o $(@)
	./$(@)
clean:
	rm -f $(TARGETS) *.vcd
distclean:
	rm -f  *~
