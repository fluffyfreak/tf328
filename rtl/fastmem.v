`timescale 1ns / 1ps

/*
    Copyright (C) 2016-2018, Stephen J. Leary
    Copyright (C) 2017, M Heinrichs
    Copyright (C) 2017, Chris "SolidCore"

    All rights reserved.
    
    This file is part of  TF328 (Terrible Fire CD32 RAM + IDE Board).

    TF530 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TF530 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TF530. If not, see <http://www.gnu.org/licenses/>.
     
     # Additional Credits # 
     
     Thank you MHeinrichs for the 0ws firmware, I took the time to write a fix
     for her for Alliance ram /others.
     
     Special thanks to Supaduper who has been a great help for all my amiga needs! Thank you sir!
     And a big thank you Steve from all of us at EAB appreciate your hard work! Keep on going 

     - SolidCore 15.10.2017  
*/


module fastmem(

           input 	    CLKCPU,
           input 	    RESET,

           input [23:0]     A,

           inout [7:0] 	    D,
           input [1:0] 	    SIZ,

           input 	    AS20,
           input 	    RW20,
           input 	    DS20,

           // ram chip control
           output reg 	    RAM_MUX,
           output reg 	    RAMOE,
           output reg [3:0] CAS,
           output reg [1:0] RAS,
           output [1:0]    RAM_A,

           output 	    RAM_ACCESS,
           output	reg RAM_READY,
           output		Z2_ACCESS

       );

wire [5:0] zaddr = {A[6:1]};

reg configured = 'b0;
reg shutup		= 'b0;
reg [7:4] data_out;
reg [7:5] base_address;

wire Z2_WRITE = (Z2_ACCESS | RW20);
wire Z2_READ = (Z2_ACCESS | ~RW20);

always @(negedge DS20 or negedge RESET) begin

    if (RESET == 1'b0) begin

        configured <= 1'b0;
        shutup <= 1'b0;

    end else begin

        if (Z2_WRITE == 1'b0) begin

            case (zaddr)
                'h24: begin
                    base_address[7:5] <= D[7:5];
                    configured <= 1'b1;
                end
                //'h25: base_address[3:0] <= D[7:4];
                'h26: shutup <= 1'b1;
            endcase
        end
        
        case (zaddr)
            'h00: data_out[7:4] <= 4'he;
            'h01: data_out[7:4] <= 4'h0;
            'h02: data_out[7:4] <= 4'hb;
            'h03: data_out[7:4] <= 4'hd;
            'h04: data_out[7:4] <= 4'h7;
            'h08: data_out[7:4] <= 4'he;
            'h09: data_out[7:4] <= 4'hc;
            'h0a: data_out[7:4] <= 4'h2;
            'h0b: data_out[7:4] <= 4'h7;
            'h11: data_out[7:4] <= 4'he;
            'h12: data_out[7:4] <= 4'hb;
            'h13: data_out[7:4] <= 4'h7;
            default: data_out[7:4] <= 4'hf;
        endcase
    end
end

// zorro II chip bank decoder.
wire [3:0] bank;
assign bank[0] = A[23:21] != 3'b001; // $200000
assign bank[1] = A[23:21] != 3'b010; // $400000
assign bank[2] = A[23:21] != 3'b011; // $600000
assign bank[3] = A[23:21] != 3'b100; // $800000

wire [1:0] chip_ras = {&bank[3:2], &bank[1:0]};
wire chip_selected = &chip_ras[1:0] | ~configured;

wire [3:0] casint;
assign casint[3] = A[1] | A[0];
assign casint[2] = (~SIZ[1] & SIZ[0] & ~A[0]) | A[1];
assign casint[1] = (SIZ[1] & ~SIZ[0] & ~A[1] & ~A[0]) | (~SIZ[1] & SIZ[0] & ~A[1]) |(A[1] & A[0]);
assign casint[0] = (~SIZ[1] & SIZ[0] & ~A[1] ) | (~SIZ[1] & SIZ[0] & ~A[0] ) | (SIZ[1] & ~A[1] & ~A[0] ) | (SIZ[1] & ~SIZ[0] & ~A[1] );

assign RAM_A =  RAM_MUX ? {A[21:20]} : {A[3:2]} ;

reg 	  AS20_D; 
reg [2:0] state = 'd0;
reg [7:0] refresh_count ='d0;
reg 	  refresh_req  ='d0;  
reg [3:0] startup_count ='d0;
      
localparam CYCLE_IDLE = 'd0,
       CYCLE_CAS = 'd1,
           CYCLE_WAIT = 'd2,
           CYCLE_CBR1 = 'd3,
           CYCLE_CBR2 = 'd4;
             
// ram state machine
always @(posedge CLKCPU, posedge AS20) begin

    if( AS20 == 1 ) begin       
       state <= CYCLE_IDLE;
       AS20_D <= 1'b1;     
       RAS <= 2'b11;
       CAS <= 4'b1111;
       RAM_READY <= 1'b1;
       RAMOE <= 1'b1;
        
    end else begin
       AS20_D <= AS20; 
       case (state)
                
     CYCLE_IDLE: begin 
        RAS <= 2'b11;
        CAS <= 4'b1111;

        if (AS20_D & ~AS20) begin 	       
           refresh_count <= refresh_count + 'd1;
        end
           
        if (refresh_count > 'd60) begin
           refresh_req <= 1;
           refresh_count <= 'd0; 
        end
        
        if (refresh_req & RW20) begin 
        CAS <= 4'b0000;
        state <= CYCLE_CBR1;
        refresh_req <= 1'b0;  
            
        end else if (chip_selected == 1'b0) begin
        RAS[0] <= chip_ras[0];
        RAS[1] <= chip_ras[1];	
        RAM_READY <= 1'b0;
        state <= CYCLE_CAS;
        RAMOE <=  1'b0;
        end
     end
           
     CYCLE_CAS: begin
        CAS[3] <= casint[3] & ~RW20;
            CAS[2] <= casint[2] & ~RW20;
            CAS[1] <= casint[1] & ~RW20;
            CAS[0] <= casint[0] & ~RW20;
        RAM_READY <= 1'b0;
        state <= CYCLE_WAIT; 
     end
           
     CYCLE_WAIT: begin  		 		
        state <= CYCLE_WAIT;
     end
         
     CYCLE_CBR1: begin
        RAS <= 2'b00;		 
        state <= CYCLE_CBR2;
     end
     
     CYCLE_CBR2: begin   
        RAS <= 2'b11;	  
        CAS <= 4'b1111;
        state <= CYCLE_IDLE;
     end
     
     default: state <= CYCLE_IDLE;
       endcase // case (state)
    end // else: !if( AS20 == 1 )
end
           
always @(negedge CLKCPU or posedge AS20) begin
     // ram address mux
     if(AS20==1)begin
            RAM_MUX <= 1'b1;
         
     end else begin 
          RAM_MUX <= &RAS;			  
    end
end

assign D = Z2_READ ? 8'bzzzzzzzz : {data_out,4'bzzzz};
assign RAM_ACCESS = (AS20 | chip_selected);
assign Z2_ACCESS = ({A[23:16]} != {8'hE8}) | AS20 | DS20 | configured | shutup;

endmodule
