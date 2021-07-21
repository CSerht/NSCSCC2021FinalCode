`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/03 21:30:03
// Design Name:
// Module Name: ALU
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

module ALU(
           // control
           input wire [3:0] op_i,    // ALU operation
           input wire alu_src_i,     // ALU source operand

           input wire [31:0] A_i,
           input wire [31:0] B_i,
           input wire [31:0] imm_ext_i,

           output reg [31:0] alu_result_o
       );

// ALU source operand
wire [31:0] op1 = A_i;
wire [31:0] op2 =
     (alu_src_i == `B_calculate)? B_i: imm_ext_i;

// multipling unit
wire signed [31 : 0] mul_result;
mult_gen_0 mulitplier (
               .A($signed(op1)),  // input wire [31 : 0] A (signed)
               .B($signed(op2)),  // input wire [31 : 0] B (signed)
               .P(mul_result)  // output wire [31 : 0] P
           );

always@(*)
begin
    case(op_i)
        `and_op:
            alu_result_o <= op1 & op2;
        `or_op:
            alu_result_o <= op1 | op2;
        `xor_op:
            alu_result_o <= op1 ^ op2;
        `sll_op:
            alu_result_o <= op1 << op2;
        `srl_op:
            alu_result_o <= op1 >> op2;
        `add_op:
            alu_result_o <= op1 + op2;
        `mul_op: //// multipling unit: 0 cycle
            alu_result_o <= mul_result;
        `lui_op:
            alu_result_o <= {op2[15:0],16'h0000};

        default:
            alu_result_o <= 0;
    endcase
end

endmodule

