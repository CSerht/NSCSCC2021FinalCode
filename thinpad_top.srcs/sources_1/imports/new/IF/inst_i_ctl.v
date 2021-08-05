`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/08/04 23:32:47
// Design Name:
// Module Name: inst_i_ctl
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Fast Mode下的指令输入处理逻辑
//              核心：保证PC + 4和inst(pc)上下的一一对应的
//              1. 当跳转指令成立，对读入的延迟槽之后的指令置nop
//              2. 当pc不允许写入，暂存当前指令并输出暂存指令
//                 直到pc允许写入，输出读取到的指令（状态机）
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"
module inst_i_ctl(
           input wire clk,
           input wire rst_n,

           input wire id_ex_isjump_i,
           input wire [31:0] inst_i,
           input wire pc_w_i,

           input wire fast_mode_start_i,

           output reg [31:0] inst_to_ifid_o
       );

localparam USE_DRAM_INST   = 2'b01; // 正常状态，使用来自dram的指令
localparam USE_INST_BUFFER = 2'b10; // PC禁止写导致暂时使用指令缓存
reg [1:0] state;
reg [31:0] inst_buffer; // 暂存指令

always@(posedge clk or posedge rst_n)
begin
    if (rst_n == `rst_enable)
    begin
        inst_buffer     <= 0;
        state           <= USE_DRAM_INST;
    end
    else if(fast_mode_start_i == `fast_mode)
    begin
        case(state)
            USE_DRAM_INST:
            begin
                if(!pc_w_i) // pc write disable
                begin
                    inst_buffer <= inst_i; // save instruction
                    state       <= USE_INST_BUFFER;
                end
            end

            USE_INST_BUFFER:
            begin
                if(pc_w_i)
                begin
                    state <= USE_DRAM_INST;
                end
            end
        endcase
    end
end


// get instruction
always@(*)
begin
    if(rst_n == `rst_enable)
    begin
        inst_to_ifid_o <= 0;
    end
    else if(fast_mode_start_i == `fast_mode)
    begin
        if(id_ex_isjump_i == `jump_enable)
        begin
            inst_to_ifid_o <= 0;
        end
        else if(state == USE_INST_BUFFER)
        begin
            inst_to_ifid_o <= inst_buffer;
        end
        else
        begin
            inst_to_ifid_o <= inst_i;
        end
    end
    else // normal mode
    begin
        inst_to_ifid_o <= inst_i;
    end
end


// (id_ex_isjump_i == `jump_enable && fast_mode_start_i == `fast_mode) ?
// 32'h0000_0000 : inst_i;


endmodule
