`timescale 1ns / 1ps
// final1.v  -  Top Level
// sw[0]=0 -> OLED solo snake
// sw[0]=1 -> VGA 2-player snake (800x600 @ 60Hz)

module final1(
    input  clk,
    input  rst,
    input  btnU, btnD, btnL, btnR,
    input  [15:0] sw,
    output [7:0] JC,
    output [3:0] vgaRed, vgaGreen, vgaBlue,
    output Hsync, Vsync,
    output [7:0] seg,
    output [3:0] an,
    output [9:0] led
);
    wire mode_vga = sw[0];

    // =========================================================
    // OLED SOLO SNAKE
    // =========================================================
    wire game_clk_oled;
    wire [1:0]   dir_oled;
    wire [5:0]   rand_x_oled, rand_y_oled;
    wire [383:0] snake_x_bus, snake_y_bus;
    wire [6:0]   length_oled;
    wire [5:0]   food_x_oled, food_y_oled;
    wire         game_over_oled;
    wire [12:0]  pixel_index;
    wire [15:0]  pixel_data;
    wire         sample_pixel, frame_begin, sending_pixels;
    

    clk_divider  u1(clk, rst, game_clk_oled);
    button_input u2(clk, rst, game_clk_oled, btnU, btnD, btnL, btnR, dir_oled);
    random_gen   u3(clk, rst, rand_x_oled, rand_y_oled);

    game_logic u4(
        game_clk_oled, rst, dir_oled, sw[2],
        rand_x_oled, rand_y_oled,
        snake_x_bus, snake_y_bus, length_oled,
        food_x_oled, food_y_oled, game_over_oled
    );

    pixel_generator u5(
        pixel_index, length_oled,
        snake_x_bus, snake_y_bus,
        food_x_oled, food_y_oled,
        game_over_oled, pixel_data
    );

    reg [15:0] pixel_data_reg;
    always @(posedge clk)
        if (sample_pixel) pixel_data_reg <= pixel_data;

    reg [2:0] clk_div=0; reg clk6p25m=0;
    always @(posedge clk) begin
        if (clk_div==3'd7) begin clk_div<=0; clk6p25m<=~clk6p25m; end
        else clk_div<=clk_div+1;
    end

    wire oled_rst = rst | mode_vga;
    oled_display oled(
        .clk(clk6p25m), .reset(oled_rst),
        .frame_begin(frame_begin), .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel), .pixel_index(pixel_index),
        .pixel_data(pixel_data_reg),
        .cs(JC[0]), .sdin(JC[1]), .sclk(JC[3]),
        .d_cn(JC[4]), .resn(JC[5]), .vccen(JC[6]), .pmoden(JC[7])
    );
    assign JC[2] = 1'b0;

    // =========================================================
    // VGA 2-PLAYER SNAKE
    // =========================================================
    wire clk40;
    clk_wiz_0 u_clk(.clk_in1(clk), .clk_out1(clk40));

    wire [10:0] hpos;
    wire [9:0]  vpos;
    wire        display_on;
    wire        vga_rst = rst;

    vga_sync u_vsync(
        .clk40(clk40), .rst(vga_rst),
        .hsync(Hsync), .vsync(Vsync),
        .display_on(display_on),
        .hpos(hpos), .vpos(vpos)
    );
    // Game tick ~6 Hz
    reg [24:0] vga_tick_cnt;
    reg        vga_game_clk;
    always @(posedge clk or posedge rst) begin
        if (rst) begin vga_tick_cnt<=0; vga_game_clk<=0; end
        else begin
            vga_tick_cnt <= vga_tick_cnt+1;
            vga_game_clk <= vga_tick_cnt[24];
        end
    end

    wire [1:0] dir2;
    sw_direction u_swdir(
        .clk(clk), .rst(rst),
        .swU(sw[15]), .swD(sw[14]), .swL(sw[13]), .swR(sw[12]),
        .dir(dir2)
    );

    wire [4:0] vrand_x, vrand_y;
    wire [1:0] vrand_type;
    vga_random_gen u_vrand(clk, rst, vrand_x, vrand_y, vrand_type);

    wire [383:0] s1x_bus, s1y_bus, s2x_bus, s2y_bus;
    wire [6:0]   len1, len2;
    wire [24:0]  vfood_x_bus, vfood_y_bus;
    wire [9:0]   vfood_type_bus;
    wire [6:0]   vscore1, vscore2;
    wire [1:0]   vmult1, vmult2;
    wire         dead1, dead2, vgame_over;

    vga_game_logic u_vgl(
        .game_clk(vga_game_clk), .rst(vga_rst),
        .dir1(dir_oled), .dir2(dir2),
        .rand_x(vrand_x), .rand_y(vrand_y), .rand_type(vrand_type),
        .s1x_bus(s1x_bus), .s1y_bus(s1y_bus),
        .s2x_bus(s2x_bus), .s2y_bus(s2y_bus),
        .len1(len1), .len2(len2),
        .food_x_bus(vfood_x_bus), .food_y_bus(vfood_y_bus),
        .food_type_bus(vfood_type_bus),
        .score1(vscore1), .score2(vscore2),
        .mult1(vmult1), .mult2(vmult2),
        .dead1(dead1), .dead2(dead2), .game_over(vgame_over)
    );

    wire [3:0] vr, vg, vb;
    vga_pixel_gen u_vpg(
        .clk40(clk40), .hpos(hpos), .vpos(vpos), .display_on(display_on),
        .s1x_bus(s1x_bus), .s1y_bus(s1y_bus), .len1(len1),
        .s2x_bus(s2x_bus), .s2y_bus(s2y_bus), .len2(len2),
        .food_x_bus(vfood_x_bus), .food_y_bus(vfood_y_bus),
        .food_type_bus(vfood_type_bus),
        .score1(vscore1), .score2(vscore2),
        .mult1(vmult1), .mult2(vmult2),
        .dead1(dead1), .dead2(dead2), .game_over(vgame_over),
        .vga_r(vr), .vga_g(vg), .vga_b(vb)
    );

    assign vgaRed   = mode_vga ? vr : 4'b0;
    assign vgaGreen = mode_vga ? vg : 4'b0;
    assign vgaBlue  = mode_vga ? vb : 4'b0;

    // =========================================================
    // 7-Segment
    // =========================================================
    score_display u_score(
        .clk(clk), .rst(rst), .mode_vga(mode_vga),
        .len_oled(length_oled),
        .score1(vscore1), .score2(vscore2),
        .seg(seg), .an(an)
    );

    // LEDs
    assign led[9]   = mode_vga ? vgame_over  : game_over_oled;
    assign led[8]   = mode_vga ? dead2       : 1'b0;
    assign led[7]   = mode_vga ? dead1       : 1'b0;
    assign led[5:4] = mode_vga ? vmult1      : 2'b0;
    assign led[3:2] = mode_vga ? vmult2      : 2'b0;
    assign led[6]   = 1'b0;
    assign led[1:0] = mode_vga ? vfood_type_bus[1:0] : 2'b0;

endmodule