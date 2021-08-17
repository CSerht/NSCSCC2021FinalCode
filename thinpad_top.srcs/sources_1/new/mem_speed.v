`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/08/16 09:30:00
// Design Name:
// Module Name: mem_speed
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

`include "../imports/new/define.v"
module mem_speed(
           input wire clk,
           input wire rst_n,

           input wire [31:0] spe_addr_i,
           input wire [31:0] spe_data_i,

           input wire [1:0] spe_mode_i,
           input wire spe_data_w_i,
           input wire spe_data_r_i,

           output wire spe_stall_pipe_o,
           output wire spe_or_mem_o, // spe data or other mem data
           output reg [31:0] spe_data_o
       );

//////////////////////////////////////////////
reg [31:0] spe_buffer;

localparam READY     = 1'b1;
localparam NOT_READY = 1'b0;
reg ready; // 为1表示处理完毕，可以读取；若为0就读取，暂停流水等待

// localparam AVAI     = 1'b1;
// localparam NOT_AVAI = 1'b0;
// reg avai; // 表示当前buffer数据是待处理数据，1代表数据可用

localparam BUSY     = 1'b1;
localparam NOT_BUSY = 1'b0;
reg busy; // 1代表忙碌，不允许写入，如果要写入，就暂停流水线等待
//////////////////////////////////////////////



/*************************************************/
/****         以下两个参数可能需要需修改        ****/
/*************************************************/
// 该参数用于指明，需要多少个周期使得ready信号有效（置1）
// 根据实际情况修改，注意是【从0开始】计数！
// 若修改频率，需要改【pll】和【串口收发器参数】
// 若降频后硬件加速器能够运行，则降频是值得的！
// 频率与WAIT_COUNT的范围
// 64MHZ: [-1,2] 且为整数
// 61MHz: [3,4]
localparam WAIT_COUNT = 1; // 等待周期数 = WAIT_COUNT + 1


// 计数器位宽，与WAIT_COUNT有关，比log2(WAIT_COUNT)大一点儿
localparam COUNTER_SIZE = 5;

///////////////////////////////////////////////////
//////////////////    加速器    ///////////////////
///////////////////////////////////////////////////
// accelerator
// 加速器处理逻辑，壳子默认不需要处理，直连

/// input
wire [31:0] spe_data_i_acc;
assign spe_data_i_acc = spe_buffer;

/// output
wire [31:0] spe_result_o;

// 通过加速器，获取spe_result
// 需要修改模块内部逻辑
// (* use_dsp = "yes" *) // 综合实现，使用DSP加速器，这个看情况！
accelerator  u_accelerator (
                 .clk                     ( clk             ),

                 .spe_data_i              ( spe_data_i_acc  ),

                 .spe_result_o            ( spe_result_o    )
             );

///////////////////////////////////////////////////
//////////////////    加速器    ///////////////////
///////////////////////////////////////////////////
/*************************************************/


// ready signal
wire data_w_buffer_pre; // for WAIT_COUNT == -1

reg [COUNTER_SIZE - 1:0] counter; // 计数器

localparam IDLE  = 2'b01;
localparam START = 2'b10;
reg [1:0] state;

always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        counter <= 0;
        ready   <= NOT_READY;
        state   <= IDLE;
    end
    else if(WAIT_COUNT == -1) // 等待0周期
    begin
        if(data_w_buffer_pre)
        begin
            ready <= READY;
        end

        if(spe_data_r_i == `data_r_enable)
        begin
            ready   <= NOT_READY;
        end
    end
    else
    begin
        case(state)
            IDLE:
            begin
                if(spe_data_r_i == `data_r_enable)
                begin
                    ready   <= NOT_READY;
                end
                counter <= 0;

                if(busy == BUSY)
                begin
                    state <= START;
                end
            end

            START:
            begin
                counter <= counter + 1;
                if(counter == WAIT_COUNT)
                begin
                    ready <= READY;
                    state <= IDLE;
                end
            end
        endcase
    end
end



// 根据CPU给出的mode处理sel
reg [3:0] sel;
always@(*)
begin
    if(rst_n == `rst_enable)
    begin
        sel <= 4'b0000;
    end
    else if(spe_mode_i == `word_mode)
    begin
        sel <= 4'b0000;
    end
    else if(spe_mode_i == `byte_mode)
    begin
        case(spe_addr_i[1:0])
            2'b00:
                sel <= 4'b1110;
            2'b01:
                sel <= 4'b1101;
            2'b10:
                sel <= 4'b1011;
            2'b11:
                sel <= 4'b0111;
            default:
                sel <= 4'b0000;
        endcase
    end
    else
    begin
        sel <= 4'b0000;
    end
end

// 根据sel结果转换要写入的数据
reg [31:0] data_i_convert;
always @(*)
begin
    case(sel)
        4'b0000:
            data_i_convert <= spe_data_i;
        4'b0111:
            data_i_convert <= {spe_data_i[7:0], 24'h00_0000};
        4'b1011:
            data_i_convert <= {8'h00, spe_data_i[7:0], 16'h0000};
        4'b1101:
            data_i_convert <= {16'h0000, spe_data_i[7:0], 8'h00};
        4'b1110:
            data_i_convert <= {24'h00_0000, spe_data_i[7:0]};
        default:
            data_i_convert <= 32'h0000_0000; // 其他情况非法
    endcase
end

//////////////////////
// write logic
//////////////////////

// 为1代表允许写入到buffer
wire data_w_buffer =
     (spe_data_w_i == `data_w_enable) &&
     (spe_addr_i[31:24] == 8'hFF)     &&
     (busy == NOT_BUSY);

assign data_w_buffer_pre = data_w_buffer;

always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        spe_buffer <= 0;
    end
    else
    begin
        if(data_w_buffer)
        begin
            spe_buffer <= data_i_convert;
        end
    end
end

// busy signal
always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        busy <= NOT_BUSY;
    end
    else
    begin
        if(data_w_buffer && (WAIT_COUNT != -1))
        begin
            busy <= BUSY;
        end
        else if(counter == WAIT_COUNT)
        begin
            busy <= NOT_BUSY;
        end
    end
end

//////////////////////
// read logic
//////////////////////



// 处理即将输出的数据，lb/lw
always @(*)
begin
    case(sel)
        4'b0000:
            spe_data_o <= spe_result_o;
        4'b0111:
            spe_data_o <= {{24{spe_result_o[31]}}, spe_result_o[31:24]};
        4'b1011:
            spe_data_o <= {{24{spe_result_o[23]}}, spe_result_o[23:16]};
        4'b1101:
            spe_data_o <= {{24{spe_result_o[15]}}, spe_result_o[15:8]};
        4'b1110:
            spe_data_o <= {{24{spe_result_o[7]}}, spe_result_o[7:0]};
        default:
            spe_data_o <= 32'h0000_0000;
    endcase
end

// stall pipeline logic, active-low
// NOTE:addr is 0xFFFF_0000 - 0xFFFF_0003
assign spe_stall_pipe_o =
       !(
           (
               (spe_data_r_i == `data_r_enable) &&
               (spe_addr_i[31:24] == 8'hFF)     &&
               (ready == NOT_READY)
           ) ||
           (
               (spe_data_w_i == `data_w_enable) &&
               (spe_addr_i[31:24] == 8'hFF)     &&
               (busy == BUSY)
           )
       );

// speed data or memory data
// 1 -- speed data; 0 -- memory data
assign spe_or_mem_o =
       (spe_data_r_i == `data_r_enable) &&
       (spe_addr_i[31:24] == 8'hFF);


endmodule
