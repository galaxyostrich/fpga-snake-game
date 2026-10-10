`timescale 1ns / 1ps
// sw_direction.v
// Player 2 direction from switches: sw[15]=U, sw[14]=D, sw[13]=L, sw[12]=R
// Same interface as button_input.v
// Prevents 180-degree reversal

module sw_direction(
    input  clk,
    input  rst,
    input  swU, swD, swL, swR,   // sw[15], sw[14], sw[13], sw[12]
    output reg [1:0] dir
);
    parameter UP=2'b00, DOWN=2'b01, LEFT=2'b10, RIGHT=2'b11;

    // Debounce (4-cycle simple majority isn't needed for switches but keeps it safe)
    reg [1:0] prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dir  <= LEFT;   // P2 starts moving left to face P1
            prev <= LEFT;
        end else begin
            prev <= dir;
            if      (swU && dir != DOWN)  dir <= UP;
            else if (swD && dir != UP)    dir <= DOWN;
            else if (swL && dir != RIGHT) dir <= LEFT;
            else if (swR && dir != LEFT)  dir <= RIGHT;
        end
    end
endmodule
