`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/25 14:32:16
// Design Name: 
// Module Name: game_logic
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


module game_logic(
    input game_clk,
    input rst,
    input [1:0] dir,
    input mode_wrap,
    input [5:0] rand_x,
    input [5:0] rand_y,

    output reg [383:0] snake_x_bus,
    output reg [383:0] snake_y_bus,
    output reg [6:0] length,
    output reg [5:0] food_x,
    output reg [5:0] food_y,
    output reg game_over
    );
    reg [5:0] snake_x [0:63];
    reg [5:0] snake_y [0:63];
    
    integer i;
    
    always @(posedge game_clk or posedge rst) begin
        if (rst) begin
            length <= 3;
            game_over <= 0;
            food_x <= 6'd7; 
            food_y <= 6'd3;
       for (i = 0; i < 64; i = i + 1) begin
                        snake_x[i] <= 6'd63;  
                        snake_y[i] <= 6'd63;
                    end
            snake_x[0] <= 8; snake_y[0] <= 5;
            snake_x[1] <= 7; snake_y[1] <= 5;
            snake_x[2] <= 6; snake_y[2] <= 5;   
            food_x <= rand_x;
            food_y <= rand_y;

        end else if (!game_over) begin
    
            // body move
            for (i = 63; i > 0; i = i - 1) begin
                if (i < length) begin
                    snake_x[i] <= snake_x[i-1];
                    snake_y[i] <= snake_y[i-1];
                end
            end
    
            // head move
            if (mode_wrap) begin
                
                case(dir)
                    2'b00: snake_y[0] <= (snake_y[0] <= 1)  ? 9  : snake_y[0] - 1; 
                    2'b01: snake_y[0] <= (snake_y[0] >= 9)  ? 1  : snake_y[0] + 1;  
                    2'b10: snake_x[0] <= (snake_x[0] <= 1)  ? 14 : snake_x[0] - 1;  
                    2'b11: snake_x[0] <= (snake_x[0] >= 14) ? 1  : snake_x[0] + 1;  
                endcase
            end else begin
                
                case(dir)
                    2'b00: snake_y[0] <= snake_y[0] - 1;
                    2'b01: snake_y[0] <= snake_y[0] + 1;
                    2'b10: snake_x[0] <= snake_x[0] - 1;
                    2'b11: snake_x[0] <= snake_x[0] + 1;
                endcase
            end
    
            // hit wall
        
            if (!mode_wrap) begin
                if (snake_x[0] == 0 || snake_x[0] == 15 ||
                    snake_y[0] == 0 || snake_y[0] == 10)
                    game_over <= 1;
            end
    
            // eat food
            if (snake_x[0] == food_x && snake_y[0] == food_y) begin
                            length <= length + 1;
                            snake_x[length] <= snake_x[length - 1];
                            snake_y[length] <= snake_y[length - 1];
                            food_x <= rand_x;
                            food_y <= rand_y;
                      end
    
            // hit itself
            for (i = 1; i < 64; i = i + 1) begin
                if (i < length &&
                    snake_x[0] == snake_x[i] &&
                    snake_y[0] == snake_y[i])
                    game_over <= 1;
            end
        end
    end
    

    always @(*) begin
        for (i = 0; i < 64; i = i + 1) begin
            snake_x_bus[i*6 +: 6] = snake_x[i];
            snake_y_bus[i*6 +: 6] = snake_y[i];
        end
    end
endmodule
