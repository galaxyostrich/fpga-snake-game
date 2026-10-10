`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/25 14:33:27
// Design Name: 
// Module Name: pixel_generator
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


module pixel_generator(
    input [12:0] pixel_index,
    input [6:0] length,
    input [383:0] snake_x_bus,
    input [383:0] snake_y_bus,
    input [5:0] food_x,
    input [5:0] food_y,
    input game_over,
    output reg [15:0] pixel_data
    );

    integer i;
    reg hit;
    reg [5:0] sx, sy;
    
    wire [6:0] x = pixel_index % 96;
    wire [6:0] y = pixel_index / 96;
    
    wire [5:0] gx = x / 6;
    wire [5:0] gy = y / 6;
    
    always @(*) begin
        hit = 0;
        
        for (i = 0; i < 64; i = i + 1) begin
            if (i < length) begin
                sx = snake_x_bus[i*6 +: 6];
                sy = snake_y_bus[i*6 +: 6];
                if (gx == sx && gy == sy && sx < 16 && sy < 11)
                    hit = 1;
            end
        end
        
        if (game_over)
            pixel_data = 16'hFFFF;
        else if (hit)
            pixel_data = 16'h07E0;
        else if (gx == food_x && gy == food_y)
            pixel_data = 16'hF800;
        else
            pixel_data = 16'h0000;
    end
endmodule
