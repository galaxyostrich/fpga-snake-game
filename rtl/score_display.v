`timescale 1ns / 1ps
// score_display.v  -  7-segment score display
// OLED mode: [3:2]=OLED score  [1:0]="--"
// VGA  mode: [3:2]=P1 score    [1:0]=P2 score
// Score is now passed directly (not computed from length)

module score_display(
    input  clk,
    input  rst,
    input  mode_vga,
    input  [6:0] len_oled,    // OLED uses length-3
    input  [6:0] score1,      // VGA P1 direct score
    input  [6:0] score2,      // VGA P2 direct score
    output reg [7:0] seg,
    output reg [3:0] an
);
    wire [6:0] score_oled = (len_oled >= 3) ? len_oled - 3 : 0;
    wire [6:0] scoreA = mode_vga ? score1 : score_oled;
    wire [6:0] scoreB = score2;

    wire [3:0] A_tens = (scoreA > 99) ? 4'd9 : scoreA / 10;
    wire [3:0] A_ones = (scoreA > 99) ? 4'd9 : scoreA % 10;
    wire [3:0] B_tens = (scoreB > 99) ? 4'd9 : scoreB / 10;
    wire [3:0] B_ones = (scoreB > 99) ? 4'd9 : scoreB % 10;

    localparam RDIV = 50_000;
    reg [16:0] rcnt;
    reg [1:0]  dsel;

    always @(posedge clk or posedge rst) begin
        if (rst) begin rcnt<=0; dsel<=0; end
        else if (rcnt==RDIV) begin rcnt<=0; dsel<=dsel+1; end
        else rcnt<=rcnt+1;
    end

    function [6:0] bcd2seg;
        input [3:0] b;
        case(b)
            4'd0: bcd2seg=7'b1000000; 4'd1: bcd2seg=7'b1111001;
            4'd2: bcd2seg=7'b0100100; 4'd3: bcd2seg=7'b0110000;
            4'd4: bcd2seg=7'b0011001; 4'd5: bcd2seg=7'b0010010;
            4'd6: bcd2seg=7'b0000010; 4'd7: bcd2seg=7'b1111000;
            4'd8: bcd2seg=7'b0000000; 4'd9: bcd2seg=7'b0010000;
            default: bcd2seg=7'b1111111;
        endcase
    endfunction

    localparam SEG_DASH = 7'b0111111;

    always @(posedge clk or posedge rst) begin
        if (rst) begin seg<=8'hFF; an<=4'b1111; end
        else case(dsel)
            2'd3: begin an<=4'b0111; seg<={1'b1,bcd2seg(A_tens)}; end
            2'd2: begin an<=4'b1011; seg<={1'b1,bcd2seg(A_ones)}; end
            2'd1: begin an<=4'b1101;
                seg<=mode_vga?{1'b1,bcd2seg(B_tens)}:{1'b1,SEG_DASH}; end
            2'd0: begin an<=4'b1110;
                seg<=mode_vga?{1'b1,bcd2seg(B_ones)}:{1'b1,SEG_DASH}; end
        endcase
    end
endmodule