`timescale 1ns / 1ps
// vga_sync.v  -  800x600 @ 60Hz
// Pixel clock: 40 MHz from clk_wiz_0
// Sync polarity: POSITIVE (both hsync and vsync)
// VESA standard timing

module vga_sync(
    input  clk40,
    input  rst,
    output reg hsync,
    output reg vsync,
    output reg display_on,
    output reg [10:0] hpos,
    output reg [9:0]  vpos
);

    localparam H_DISPLAY = 800;
    localparam H_FRONT   = 40;
    localparam H_SYNC    = 128;
    localparam H_BACK    = 88;
    localparam H_TOTAL   = 1056;

    localparam V_DISPLAY = 600;
    localparam V_FRONT   = 1;
    localparam V_SYNC    = 4;
    localparam V_BACK    = 23;
    localparam V_TOTAL   = 628;

    reg [10:0] h_cnt;
    reg [9:0]  v_cnt;

    always @(posedge clk40 or posedge rst) begin
        if (rst) begin
            h_cnt <= 0; v_cnt <= 0;
            hpos  <= 0; vpos  <= 0;
            hsync <= 1; vsync <= 1;
            display_on <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                v_cnt <= (v_cnt == V_TOTAL - 1) ? 0 : v_cnt + 1;
            end else
                h_cnt <= h_cnt + 1;

            hpos       <= h_cnt;
            vpos       <= v_cnt;
            display_on <= (h_cnt < H_DISPLAY) && (v_cnt < V_DISPLAY);

            // Positive polarity - required for 800x600
            hsync <= (h_cnt >= H_DISPLAY + H_FRONT &&
                      h_cnt <  H_DISPLAY + H_FRONT + H_SYNC);
            vsync <= (v_cnt >= V_DISPLAY + V_FRONT &&
                      v_cnt <  V_DISPLAY + V_FRONT + V_SYNC);
        end
    end
endmodule