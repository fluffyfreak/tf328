`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////

module write_cycle_tb;
   

   reg RESET;
   reg CLK14M;
   wire CLK;
   
   reg AS20;
   reg DS20;
   reg RW20;
   
   reg [31:0] A;
   reg [31:0] D_OUT;
   
   reg [1:0]  SIZ;
   wire [1:0]  DSACK;

   wire       RAMOE;
   wire [1:0] RAS;
   wire [3:0] CAS;

   wire [31:0] D = RW20 ? {32{1'bz}} : D_OUT;


`include "common.vinc"
   
   // Instantiate the Unit Under Test (UUT)
   ramcpld uut (
		  
   	        .CLKCPU(CLK), 
		.RESET(RESET),
					
		.AS20(AS20), 
		.DS20(DS20), 
		.RW20(RW20),
 
		.DSACK(DSACK),
		.PUNT (PUNT),
		.SIZ(SIZ), 

		.A(A[23:0]), 
			
		.D (D[31:24]),
		  
		.IDEINT ( 1'b0 ),

		.RAMOE	(RAMOE),
		.CAS	(CAS),
		.RAS	(RAS),
		.RAM_MUX(RAM_MUX)
		
	);

   integer     i;
	initial begin
	   
	   $dumpfile("write_cycle.vcd");
	   $dumpvars(0, write_cycle_tb);
	   
	   RESET = 1;
	   #10;
	   
	   // Initialize Inputs
	   CLK14M = 0;
	   RESET = 0;
	   
	   // Wait 100 ns for global reset to finish
	   #142;
		
	   RESET = 1;

	   #142;
	   
	   SIZ = 2'b10;
	   // autoconfig the devices. 
	   write(32'h00E8004a, 32'h9_0000000);
	   write(32'h00E80048, 32'hE_0000000);
	   
	   write(32'h00E8004a, 32'h0_0000000);
	   write(32'h00E80048, 32'h2_0000000);

	   busidle();

	   for( i = 32'h200000; i < 32'h00210000; i++ ) begin
	   
	      write(i, 0);
	      busidle();
	      read(i);
	      busidle();
	   
	   end

		#1000000;
	   
	   $finish;
	end
   
assign CLK = CLK14M;

always 	begin
    #71; CLK14M = ~CLK14M;
end

PULLUP PUNT_pullup (
.O(PUNT) // Pullup output (connect directly to top-level port)
);

PULLUP DSACK0_pullup (
.O(DSACK[0]) 
);

PULLUP DSACK1_pullup (
.O(DSACK[1]) 
);

   
endmodule

