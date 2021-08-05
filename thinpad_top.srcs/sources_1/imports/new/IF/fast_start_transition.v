`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/08/04 17:01:40
// Design Name:
// Module Name: fast_start_transition
// Project Name:
// Target Devices:
// Tool Versions:
// Description: mode_convert切换到PREPARE_OPEN状态之后还需要等待2个周期，插入两个nop
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"
module fast_start_transition(
           input wire clk,
           input wire rst_n,

           input wire fast_mode_start_i,

           output reg if_id_clear_o
       );

localparam WAIT          = 3'b001; // 等待Fast Mode启动
localparam INSERT_NOP    = 3'b010; // 插入nop
localparam WAIT_RECOVREY = 3'b100; // 等待Normal Mode，恢复到WAIT状态
reg [2:0] state;

always@(posedge clk or posedge rst_n)
begin
    if (rst_n == `rst_enable)
    begin
        if_id_clear_o <= `clear_disable;
        state <= WAIT;
    end
    else
    begin
        case(state)
            WAIT:
            begin
                if(fast_mode_start_i == `fast_mode)
                begin
                    if_id_clear_o <= `clear_enable;
                    state <= INSERT_NOP;
                end
                else
                begin
                    if_id_clear_o <= `clear_disable;
                    state <= WAIT;
                end
            end

            INSERT_NOP:
            begin
                if_id_clear_o <= `clear_enable;
                state <= WAIT_RECOVREY;
            end

            WAIT_RECOVREY: 
            begin
                if(fast_mode_start_i == `normal_mode)
                begin
                    state <= WAIT;
                end
                else
                begin
                    if_id_clear_o <= `clear_disable;
                end
            end
        endcase
    end
end

endmodule
