`timescale 1ns / 1ps
/*  muxcpld.v

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


module muxcpld (
	input RAM_MUX,
	input CLKCPU,
	input [19:3] A,
	output [9:2] RAM_A,
	input  JMP,
	output [2:0] IPL
);

assign RAM_A = RAM_MUX ? {A[19:12]} : {A[11:4]};

assign IPL = 3'bzzz;

endmodule