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
wire GAYLE_IDE;

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
    .A      ( {A[13:12]}	),
    .IDE_INT( IDEINT        ),
    .INT2   ( GAYLE_INT2    ),
    .D7	    ( D[7]	        ),
	.DOUT7	( gayle_dout  	 )

);

// module to control IDE timings. 
ata ATA (

	.CLK	( CLKCPU	), 
	.AS	( AS20	),
	.RW	( RW20	),
	.A		( A		),
	.WAIT	( 1'b1   ), 
	
	.IDECS( IDECS	),
	.IOR	( IOR		),
	.IOW	( IOW		),
	.DTACK( DTACK_IDE	),
   .ACCESS( GAYLE_IDE )
	
);

reg AS20_D = 1'b1;
reg AS20_D2 = 1'b1;

fastmem FASTRAM( 
					
					.CLKCPU		( CLKCPU	),
					.RESET		( RESET),
					.AS20		( AS20     ),
					.DS20		( DS20		),
					.RW20		( RW20		),
        
					.A			( A			), 
					.D			( D			),
					.SIZ		( SIZ		),
			
					.CAS		( CAS		),
					.RAS		( RAS		),
					
					.RAM_MUX 	( RAM_MUX	),
					.RAMOE 		( RAMOE		),
					.RAM_A 		( RAM_A		),
					.RAM_ACCESS ( RAM_ACCESS),
					
					.Z2_ACCESS 	( Z2_ACCESS	),
					.WAIT		( RAM_WAIT )
					
               );

reg intcycle_dout = 1'b0;

reg GAYLE_D  = 1'b1;
reg GAYLE_D2 = 1'b1;

wire DSHOLD2 = {AS20_D,AS20, RW20} == {1'b1,1'b0,1'b0};
wire IOR_INT = ~RW20 | GAYLE_IDE | DSHOLD2;
wire IOW_INT = RW20 | GAYLE_IDE | DSHOLD2; 

wire fastcycle_int =   (RAM_ACCESS | RAM_WAIT) & GAYLE_D2 & Z2_ACCESS & GAYLE_ACCESS & DTACK_IDE;
	
FDCP #(.INIT(1'b1)) 
	FASTCYCLE1_FF (
		.Q(FASTCYCLE1), // Data output
		.C(CLKCPU), // Clock input
		.CLR(1'b0), // Asynchronous clear input
		.D(fastcycle_int), // Data input
		.PRE(AS20) // Asynchronous set input
);

FDCP #(.INIT(1'b1)) 
	FASTCYCLE0_FF (
		.Q(FASTCYCLE0), // Data output
		.C(CLKCPU), // Clock input
		.CLR(1'b0), // Asynchronous clear input
		.D(fastcycle_int | RAM_ACCESS), // Data input
		.PRE(AS20) // Asynchronous set input
);

 
always @(posedge CLKCPU or posedge AS20) begin	
	
	 if (AS20 == 1'b1) begin 

		AS20_D <= 1'b1;
		AS20_D2 <= 1'b1;
		GAYLE_D <= 1'b1;
		GAYLE_D2 <= 1'b1;
		
	end else begin 

		intcycle_dout <= (~GAYLE_ACCESS) & RW20;
		AS20_D <= AS20;
		AS20_D2 <= AS20_D;
		GAYLE_D2 <= GAYLE_D;
		
		if (GAYLE_IDE == 1'b0) begin 
			
			GAYLE_D <= 1'b0;
		
		end
	end
	 
end

assign PUNT = POR[2] | GAYLE_ACCESS & GAYLE_IDE & RAM_ACCESS & Z2_ACCESS  ? 1'bz : 1'b0;

assign INT2 = GAYLE_INT2 ? 1'b0 : 1'bz;
wire [7:4] data_out = GAYLE_ACCESS ? 4'b1111 : {gayle_dout,3'b000};

assign D[7:0] = (intcycle_dout) ? {data_out[7:4], 4'h0} : 8'bzzzzzzzz;   

assign DSACK[1] = FASTCYCLE1 ? 1'bz : 1'b0;
assign DSACK[0] = FASTCYCLE0 ? 1'bz : 1'b0;

endmodule


