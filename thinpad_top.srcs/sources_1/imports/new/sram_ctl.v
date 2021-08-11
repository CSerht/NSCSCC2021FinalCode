`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/28 16:52:25
// Design Name:
// Module Name: sram_ctl
// Project Name:
// Target Devices:
// Tool Versions:
// Description: SRAM控制器，能够控制baseRAM和extRAM
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"
module sram_ctl(
           input wire clk,
           input wire rst_n,

           // from CPU IF stage
           //    input wire [1:0] base_mode_i,
           input wire [3:0] data_sel_i,

           input wire data_w_i, // 写使能，高有效
           input wire data_r_i, // 读使能，高有效
           input wire data_ce_i, // 芯片使能，高有效，留有端口但是内部不使用

           input  wire [31:0] data_addr_i,
           (*mark_debug = "true"*)input  wire [31:0] data_i,
           (*mark_debug = "true"*)output wire [31:0] data_o,


           // signal to cpu  active-high
           output reg sram_ctl_busy_o,
           output reg data_r_finish_o,
           output reg data_w_finish_o,


           // from Base RAM, inst RAM
           inout wire[31:0] sram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享，暂时恒输出

           output reg [19:0] sram_addr, //BaseRAM地址
           output reg [3:0] sram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
           output reg  sram_ce_n,       //BaseRAM片选，低有效
           output reg  sram_oe_n,       //BaseRAM读使能，低有效
           output reg  sram_we_n        //BaseRAM写使能，低有效
       );

// FSM state 独热码
localparam IDLE  = 3'b001;
localparam READ  = 3'b010;
localparam WRITE = 3'b100;

// tristate. if(W_ENBALE) inout --> output,write data to SRAM
localparam W_ENABLE  = 2'b01;
localparam W_DISABLE = 2'b10; // rear data from SRAM

reg [2:0] current_state;
reg [31:0] data_from_SRAM;
reg [31:0] data_to_SRAM;
reg [1:0] tristate;


// initial
// begin
//     // cpu
//     sram_ctl_busy_o  <= `sram_idle;
//     data_r_finish_o <= `data_read_unfinish;
//     // 写入完成，意味着当前没有数据被写入，平时就是这个状态！
//     // 还有成功写入数据之后，也会从unfinish进入finish状态
//     data_w_finish_o <= `data_write_finish; // NOTE

//     // base ram
//     sram_addr <= 0;
//     sram_be_n   <= 0;
//     sram_ce_n   <= 1;
//     sram_oe_n   <= 1;
//     sram_we_n   <= 1;

//     // internal data
//     current_state  <= IDLE;
//     data_from_SRAM <= 32'h0000_0000;
//     data_to_SRAM   <= 32'h0000_0000;
//     tristate       <= W_DISABLE;
// end

always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        // cpu
        sram_ctl_busy_o  <= `sram_idle;
        data_r_finish_o <= `data_read_unfinish;
        // 写入完成，意味着当前没有数据被写入，平时就是这个状态！
        // 还有成功写入数据之后，也会从unfinish进入finish状态
        data_w_finish_o <= `data_write_finish; // NOTE

        // base ram
        sram_addr <= 0;
        sram_be_n   <= 0;
        sram_ce_n   <= 1;
        sram_oe_n   <= 1;
        sram_we_n   <= 1;

        // internal data
        current_state  <= IDLE;
        data_from_SRAM <= 32'h0000_0000;
        data_to_SRAM   <= 32'h0000_0000;
        tristate       <= W_DISABLE;
    end
    else
    begin
        case (current_state)
            IDLE:
            begin
                // internal data
                tristate       <= W_DISABLE;

                // cpu
                sram_ctl_busy_o  <= `sram_idle;
                data_r_finish_o <= `data_read_unfinish;
                data_w_finish_o <= `data_write_finish;

                // base ram
                sram_ce_n   <= 0;
                sram_oe_n   <= 0;
                sram_we_n   <= 1;
                // ###########################################
                // NOTE！与取指不同，取指一直连续读，关注不读的部分
                // 取数据只是偶尔取，数据准备好之后，data_read
                // 依然是高电平，需要上升沿之后才下降（进入MEM）
                // 这会导致ext控制器再一次读取，但实际上已经读完
                // 这会导致连续load出错！
                // ###########################################
                if(data_r_i == `data_read_enable && data_r_finish_o == `data_read_unfinish)
                begin
                    sram_be_n   <= data_sel_i;
                    sram_addr <= data_addr_i[21:2];
                    current_state   <= READ;
                end
                else if(data_w_i == `data_write_enable)
                begin
                    data_to_SRAM     <= data_i;
                    sram_be_n        <= data_sel_i;
                    sram_addr        <= data_addr_i[21:2];
                    current_state    <= WRITE;
                end
                else // not read and write
                begin
                    sram_be_n        <= 0;
                    current_state    <= IDLE;
                end
            end

            READ:
            begin
                data_from_SRAM    <= sram_data;
                data_r_finish_o   <= `data_read_finish;
                sram_ctl_busy_o    <= `sram_busy;

                current_state     <= IDLE;
            end

            WRITE:
            begin
                data_w_finish_o <= `data_write_unfinish;
                sram_we_n   <= 0;
                sram_ctl_busy_o  <= `sram_busy;

                current_state <= IDLE;
                tristate      <= W_ENABLE;
            end
        endcase
    end
end

assign sram_data =
       (tristate == W_ENABLE)?
       data_to_SRAM : 32'hzzzz_zzzz;

assign data_o = data_from_SRAM;

endmodule
