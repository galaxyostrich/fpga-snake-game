`timescale 1ns / 1ps

module button_input(
    input clk,           
    input rst,
    input game_clk,      
    input btnU, btnD, btnL, btnR,
    output reg [1:0] dir
);
    parameter UP=2'b00, DOWN=2'b01, LEFT=2'b10, RIGHT=2'b11;
    
    reg [1:0] real_dir;  

  
    reg game_clk_d1, game_clk_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_clk_d1 <= 0;
            game_clk_d2 <= 0;
        end else begin
            game_clk_d1 <= game_clk;
            game_clk_d2 <= game_clk_d1;
        end
    end
    wire game_tick = game_clk_d1 && ~game_clk_d2; 


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dir <= RIGHT;
            real_dir <= RIGHT;
        end else begin
            
            if (game_tick) begin
                real_dir <= dir;
            end

            
            if      (btnU && real_dir != DOWN)  dir <= UP;
            else if (btnD && real_dir != UP)    dir <= DOWN;
            else if (btnL && real_dir != RIGHT) dir <= LEFT;
            else if (btnR && real_dir != LEFT)  dir <= RIGHT;
        end
    end
endmodule