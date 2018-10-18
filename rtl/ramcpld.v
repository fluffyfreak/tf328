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

reg [2:0] POR = 3'b111;
   
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

wire fastcycle_int = Z2_ACCESS;
wire FASTCYCLE = fastcycle_int | AS20;

always @(posedge CLKCPU or negedge RESET) begin	

   if (RESET == 1'b0) begin

      POR <= 'h7;

   end else begin

      // shift until all 0's
      // this will not happen if there isnt a clock
      POR[2:0] <= {POR[1:0], 1'b0};
      
   end

end
 
assign PUNT = POR[2] | RAM_ACCESS & Z2_ACCESS  ? 1'bz : 1'b0;

assign INT2 = 1'bz;
assign DSACK[1] = FASTCYCLE & RAM_READY ? 1'bz : 1'b0;
assign DSACK[0] = RAM_READY? 1'bz : 1'b0;

endmodule
