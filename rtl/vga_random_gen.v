`timescale 1ns / 1ps
// vga_random_gen.v  -  generates food position + type
// rand_type: weighted distribution
//   00 (normal)  = 50% chance  (lfsr[1:0] == 00 or 01)
//   01 (bonus)   = 25% chance  (lfsr[1:0] == 10)
//   10 (speed)   = 18% chance  (lfsr[1:0] == 11, lfsr[3]=0)
//   11 (poison)  = 12% chance  (lfsr[1:0] == 11, lfsr[3]=1)

module vga_random_gen(
    input  clk,
    input  rst,
    output reg [4:0] rand_x,
    output reg [4:0] rand_y,
    output reg [1:0] rand_type
);
    reg [15:0] lfsr;
    reg [15:0] free_counter;

    always @(posedge clk)
        free_counter <= free_counter + 1;

    always @(posedge clk or posedge rst) begin
        if (rst) lfsr <= 16'hACE1 ^ free_counter;
        else lfsr <= {lfsr[14:0], lfsr[15]^lfsr[14]^lfsr[12]^lfsr[3]};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_x <= 5'd16; rand_y <= 5'd12; rand_type <= 0;
        end else begin
            rand_x <= (lfsr[9:5]  % 28) + 2;   // 2..29 (inside walls)
            rand_y <= (lfsr[15:11]% 21) + 2;   // 2..22

            // Food type weighting via LFSR bits
            case (lfsr[3:2])
                2'b00: rand_type <= 2'd0;  // normal  (25%)
                2'b01: rand_type <= 2'd0;  // normal  (25%) = 50% total
                2'b10: rand_type <= 2'd1;  // bonus   (25%)
                2'b11: rand_type <= lfsr[4] ? 2'd3 : 2'd2; // poison/speed
            endcase
        end
    end
endmodule