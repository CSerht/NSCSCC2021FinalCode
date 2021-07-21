`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/21 20:49:19
// Design Name:
// Module Name: imm_extension
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


`include "../define.v"

module imm_extension(
           // control
           input wire zero_sign_ext_i,

           input wire [15:0] imm,

           output reg [31:0] imm_ext_o
       );

always@(*)
begin
    if(zero_sign_ext_i == `imm_zero_extension)
    begin
        imm_ext_o <= {16'b0,imm};
    end
    else if(zero_sign_ext_i == `imm_sign_extension)
    begin
        imm_ext_o <= (imm[15] == 0)? {16'b0,imm}: {16'hFFFF,imm};
    end
end

endmodule
