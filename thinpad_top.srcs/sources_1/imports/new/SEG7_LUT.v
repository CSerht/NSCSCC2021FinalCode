module SEG7_LUT (   oSEG1,iDIG   );
input   wire[3:0]   iDIG;  // 4位二进制，能够表示数字 0 ~ F
output  wire[7:0]   oSEG1; // 能够通过7段数码管，显示A-F，小数点恒不亮
reg     [6:0]   oSEG;

always @(iDIG)
begin
    case(iDIG)
        4'h1:      // gfabedc // if (bit value= 0),  A digital tube will be lightened.
            oSEG = 7'b1110110;    // ---t----   // rt rb lighten, show '1'
        4'h2:
            oSEG = 7'b0100001;    // |      |   // show '2'
        4'h3:
            oSEG = 7'b0100100;    // lt    rt   // '3'
        4'h4:
            oSEG = 7'b0010110;    // |      |   // '4'
        4'h5:
            oSEG = 7'b0001100;    // ---m----   // '5'
        4'h6:
            oSEG = 7'b0001000;    // |      |   // '6'
        4'h7:
            oSEG = 7'b1100110;    // lb    rb
        4'h8:
            oSEG = 7'b0000000;    // |      |
        4'h9:
            oSEG = 7'b0000110;    // ---b----
        4'ha:
            oSEG = 7'b0000010;                  // 'A'
        4'hb:
            oSEG = 7'b0011000;
        4'hc:
            oSEG = 7'b1001001;
        4'hd:
            oSEG = 7'b0110000;
        4'he:
            oSEG = 7'b0001001;
        4'hf:
            oSEG = 7'b0001011;  // 'F'
        4'h0:
            oSEG = 7'b1000000;  // '0'
    endcase
end

assign oSEG1 = {~oSEG,1'b0}; // 此处小数点永远不会亮

endmodule
