`timescale 1ns / 1ps
/*  tf528_ram_top.v

	Copyright (C) 2016-2017, Stephen J. Leary
	All rights reserved.
	
	This file is part of  TF328 (Terrible Fire CD32 RAM + IDE BOARD)

    TF328 is free: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TF530 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TF328. If not, see <http://www.gnu.org/licenses/>.
*/


module ramcpld(

		input	CLKCPU,
		input	RESET,

		input	[23:0] A,
		
		inout	[7:0] D,
		input [1:0] SIZ,
		
		input   IDEINT,
      output  INT2,
        
		input 	AS20,
		input		RW20,
		input 	DS20,
		
		// ram chip control
		output 		 RAM_MUX,		
		output 		 RAMOE,
		output [3:0] CAS,
		output [1:0] RAS,
		output [1:0] RAM_A,

		output [1:0] DSACK,
		output		 PUNT,
		
		output		 IOR,
		output		 IOW,
		
		output [1:0] IDECS

       );

// produce an internal data strobe
wire GAYLE_INT2;

// $DA0000
wire GAYLE_IDE = ({A[23:15]} != {8'hDA,1'b0}) | AS20;

// $DE0000 or $DA8000 (Ignores A18)
wire GAYLE_REGS = (A[23:15] != {8'hDA, 1'b1});

wire GAYLE_ID= (A[23:15] != {8'hDE, 1'b0});
wire GAYLE_ACCESS = (GAYLE_ID & GAYLE_REGS) | AS20;

reg [2:0] POR = 3'b111;

wire gayle_dout;
   
gayle GAYLE(

    .CLKCPU ( CLKCPU        ),
    .RESET  ( RESET         ),
    .CS     ( GAYLE_ACCESS  ),
    .DS     ( DS20  | GAYLE_ACCESS       ),
    .RW     ( RW20          ),
    .A18    ( A[18]         ),
    .A      ( {A[13:12]}	 ),
    .IDE_INT( IDEINT        ),
    .INT2   ( GAYLE_INT2    ),
    .D7	   ( D[7]	       ),
	 .DOUT7	( gayle_dout  	 )

);

fastmem FASTRAM( 
					
					.CLKCPU	(	CLKCPU	),
					.RESET	(	RESET & ~POR[2]	),
					.AS20		(	AS20     ),
					.DS20		(  DS20		),
					.RW20		(  RW20		),
        
					.A			(	A			), 
					.D			(	D			),
					.SIZ		(  SIZ		),
			
					.CAS		(  CAS		),
					.RAS		(  RAS		),
					
					.RAM_MUX ( 	RAM_MUX	),
					.RAMOE 	( 	RAMOE		),
					.RAM_A 	( 	RAM_A		),
					.RAM_ACCESS (RAM_ACCESS),
					.RAM_READY (RAM_READY),
					.Z2_ACCESS (Z2_ACCESS)
					
               );

reg intcycle_dout = 1'b0;

reg GAYLE_IDE_D = 1'b1;

assign IOR = ~RW20 | GAYLE_IDE;
assign IOW =  RW20 | GAYLE_IDE;

wire fastcycle_int = GAYLE_ACCESS & GAYLE_IDE & Z2_ACCESS;// & GAYLE_IDE_D;
wire FASTCYCLE = fastcycle_int | AS20;

//reg FASTCYCLE;
//always @(posedge CLKCPU or posedge AS20) begin	
//
//   if (AS20 == 1) begin
//      FASTCYCLE <= 1;
//		  IOR <= 1;
//      IOW <= 1;
//   end else begin
//      FASTCYCLE <= fastcycle_int;      
//      IOR <= ~RW20 | GAYLE_IDE;
//      IOW <=  RW20 | GAYLE_IDE;
//   end
//end

reg [7:0] test_reg = 'd0;

always @(posedge CLKCPU or negedge RESET) begin	

   if (RESET == 1'b0) begin

      POR <= 'hF;

   end else begin

      // shift until all 0's
      // this will not happen if there isnt a clock
      POR[2:0] <= {POR[1:0], 1'b0};
      
   end

end
 
always @(posedge CLKCPU) begin	
	 GAYLE_IDE_D <= GAYLE_IDE;
    intcycle_dout <= (~GAYLE_ACCESS) & RW20; 
end

assign PUNT = POR[2] | GAYLE_ACCESS & GAYLE_IDE & RAM_ACCESS & Z2_ACCESS  ? 1'bz : 1'b0;
assign IDECS = A[12] ? {GAYLE_IDE, 1'b1} : {1'b1, GAYLE_IDE}; 

assign INT2 = GAYLE_INT2 ? 1'b0 : 1'bz;
wire [7:4] data_out = GAYLE_ACCESS ? 4'b1111 : {gayle_dout,3'b000};

assign D[7:0] = (intcycle_dout) ? {data_out[7:4], 4'h0} : 8'bzzzzzzzz;   

assign DSACK[1] = FASTCYCLE  & RAM_READY ? 1'bz : 1'b0;
assign DSACK[0] = RAM_READY? 1'bz : 1'b0;

endmodule
