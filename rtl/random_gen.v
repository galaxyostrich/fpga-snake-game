`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/25 14:31:13
// Design Name: 
// Module Name: random_gen
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


module random_gen(
    input clk,
    input rst,
    output reg [5:0] rand_x,
    output reg [5:0] rand_y
    );
   reg [7:0] lfsr;
   reg [7:0] free_counter; 
    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 8'hAA^ free_counter;
        else
            lfsr <= {lfsr[6:0], lfsr[7]^lfsr[5]};
    end
    
    always @(posedge clk  or posedge rst) begin
       if (rst) begin
                rand_x <= 6'd7;   
                rand_y <= 6'd3;
            end else begin 
                rand_x <= (lfsr[5:0] % 14) + 1;  // 1~14
                rand_y <= (lfsr[7:2] % 9)  + 1;  // 1~9
            end
    end 
endmodule
