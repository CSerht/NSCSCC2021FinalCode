// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company:
// // Engineer:
// //
// // Create Date: 2021/07/27 18:48:21
// // Design Name:
// // Module Name: pc_stall
// // Project Name:
// // Target Devices:
// // Tool Versions:
// // Description:
// //
// // Dependencies:
// //
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// //
// //////////////////////////////////////////////////////////////////////////////////

`include "../define.v"
module pc_stall(
           input wire fast_mode_start_i,

           input wire inst_r_finish_i,
           input wire baseram_w_finish_i,

           output reg pc_w_o,
           output reg if_id_clear_o
       );

always@(*)
begin
    if(fast_mode_start_i == `normal_mode)
    begin
        if(baseram_w_finish_i == `inst_write_unfinish)
        begin
            pc_w_o        <= `pc_disable;
            if_id_clear_o <= `clear_enable;
        end
        else if(inst_r_finish_i == `inst_read_unfinish)
        begin
            pc_w_o        <= `pc_enable;
            if_id_clear_o <= `clear_enable; // clear IF/ID inst -- nop
        end
        else
        begin
            pc_w_o        <= `pc_disable;
            if_id_clear_o <= `clear_disable;
        end
    end
    else // fast mode 情况下
    begin
        pc_w_o        <= `pc_enable;
        if_id_clear_o <= `clear_disable;
    end
end


endmodule
