`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/23 21:03:18
// Design Name:
// Module Name: ext_ram_ctl
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


module ext_ram_ctl(
           // from CPU

           input wire [1:0] mode_i,
           // 以下三个均高电平有效
           input wire data_w_i,
           input wire data_r_i,
           input wire data_ce_i,

           input wire [31:0] data_addr_i, // 来自CPU的数据虚拟地址
           input wire [31:0] data_i,    // 待写入的数据
           output reg [31:0] data_o,   // 读取到的数据

           //ExtRAM信号
           inout wire[31:0] ext_ram_data,  //ExtRAM数据
           output wire[19:0] ext_ram_addr, //ExtRAM地址
           output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
           output wire ext_ram_ce_n,       //ExtRAM片选，低有效
           output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
           output wire ext_ram_we_n       //ExtRAM写使能，低有效
       );

// mode --> data_sel_i
reg [3:0] data_sel_i = 0;  // 字节使能选择信号 取决于 {lb/lw，addr[1:0]}
always @(*)
begin
    if(mode_i == 2'b10) // word select
        data_sel_i <= 4'b0000;
    else if(mode_i == 2'b00) // byte select
    begin
        case(data_addr_i[1:0])
            2'b00:
                data_sel_i <= 4'b1110;
            2'b01:
                data_sel_i <= 4'b1101;
            2'b10:
                data_sel_i <= 4'b1011;
            2'b11:
                data_sel_i <= 4'b0111;
            default:
                data_sel_i <= 4'b0000;
        endcase
    end
end

reg [31:0] data_i_convert;
// 转换写入字节
always @(*)
begin
    case(data_sel_i)
        4'b0000:
            data_i_convert <= data_i;
        4'b0111:
            data_i_convert <= {data_i[7:0], 24'h00_0000};
        4'b1011:
            data_i_convert <= {8'h00, data_i[7:0], 16'h0000};
        4'b1101:
            data_i_convert <= {16'h0000, data_i[7:0], 8'h00};
        4'b1110:
            data_i_convert <= {24'h00_0000, data_i[7:0]};
        default:
            data_i_convert <= 32'h0000_0000; // 其他情况非法
    endcase
end


assign ext_ram_data = (data_w_i == 1)? data_i_convert: 32'hzzzz_zzzz;
wire [31:0] data_temp_o = ext_ram_data; // 临时的data_o，还需要根据sel处理

// 假设data_addr的范围是0xA000_0000 ~ BFFF_FFFF，求物理地址
wire [31:0] addr_i_physical = {3'b000, data_addr_i[28:0]};
assign ext_ram_addr = addr_i_physical[21:2];

assign ext_ram_be_n = data_sel_i;
assign ext_ram_oe_n = !data_r_i;
assign ext_ram_we_n = !data_w_i;

assign ext_ram_ce_n = (!data_ce_i) ||
       (data_ce_i && data_r_i && data_w_i) ||
       (data_ce_i && !data_r_i && !data_w_i);


// 根据字节使能，处理要输出的data
always@(*)
begin
    case(data_sel_i)
        4'b0000:
            data_o <= data_temp_o;
        4'b0111:
            data_o <= {{24{data_temp_o[31]}}, data_temp_o[31:24]};
        4'b1011:
            data_o <= {{24{data_temp_o[23]}}, data_temp_o[23:16]};
        4'b1101:
            data_o <= {{24{data_temp_o[15]}}, data_temp_o[15:8]};
        4'b1110:
            data_o <= {{24{data_temp_o[7]}}, data_temp_o[7:0]};
        default:
            data_o <= 32'hzzzz_zzzz;
    endcase
end

endmodule
