`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/21 15:26:48
// Design Name:
// Module Name: reg_files
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

module reg_files(
           input wire clk,
           input wire rst_n,

           // write port
           input wire reg_we_i, // reg write enable
           input wire [4:0]  rW,
           input wire [31:0] wr_data_i,


           input wire [31:0] jal_i,
           input wire jal_en_i,

           // read port A
           input  wire [4:0]  rA,
           output reg [31:0] A,

           // read port B
           input  wire [4:0]  rB,
           output reg [31:0] B
       );


reg [31:0] register [31:0];
initial
    register[0] = 0;

/***********************/
/***** read port A *****/
/***********************/

always@(*)
begin
    if(rst_n == `rst_enable)
    begin
        A <= 0;
    end
    else if(rA == `zero_register)
    begin
        A <= 0;
    end
    else
    begin
        A <= register[rA];
    end
end

/***********************/
/***** read port B *****/
/***********************/

always@(*)
begin
    if(rst_n == `rst_enable)
    begin
        B <= 0;
    end
    else if(rB == `zero_register)
    begin
        B <= 0;
    end
    else
    begin
        B <= register[rB];
    end
end

/***********************/
/***** write port  *****/
/***********************/


// NOTE: first write; second read
always@(negedge clk)
begin
    if(rst_n == `rst_disable)
    begin
        if((reg_we_i == `reg_write_enable) && (rW != `zero_register))
        begin
            if(jal_en_i == `jal_disable)
                register[rW] <= wr_data_i;
            else
                register[31] <= jal_i; // jal instruction
        end
        else
            ;
    end
    else
        ;
end

endmodule

