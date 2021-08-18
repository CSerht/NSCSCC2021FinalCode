`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/03 21:30:52
// Design Name:
// Module Name: ALU_ctl
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

module ALU_ctl(
           input wire [3:0] alu_op_i,
           input wire [5:0] func,

           output reg [3:0] op_o
       );

always@(*)
begin
    case(alu_op_i)
        `Rtype_alu_op:
        begin
            case (func)
                `and_func:
                    op_o <= `and_op;
                `or_func:
                    op_o <= `or_op;
                `xor_func:
                    op_o <= `xor_op;
                `sll_func:
                    op_o <= `sll_op;
                `srl_func:
                    op_o <= `srl_op;
                `sllv_func:
                    op_o <= `sllv_op;
                `addu_func:
                    op_o <= `add_op;
                ////////////////////////////////
                `sltu_func:
                    op_o <= `sltu_op;
                ////////////////////////////////

                default:
                    op_o <= `other_op;
            endcase
        end
        `mul_alu_op:
            op_o <= `mul_op;
        `lui_alu_op:
            op_o <= `lui_op;
        `andi_alu_op:
            op_o <= `and_op;
        `ori_alu_op:
            op_o <= `or_op;
        `xori_alu_op:
            op_o <= `xor_op;
        `add_alu_op:
            op_o <= `add_op;

        default:
            op_o <= `other_op;
    endcase
end

endmodule

