`timescale 1ns / 1ps
// vga_game_logic.v  -  2-player snake, 5 simultaneous foods
// Food types: 0=normal(+1xmult) 1=bonus(+3 fixed) 2=speed(+2 fixed) 3=poison(-1)
// Multiplier only applies to normal food (type 0)
// 5 foods on screen at all times - each has own position+type

module vga_game_logic(
    input  game_clk,
    input  rst,
    input  [1:0] dir1,
    input  [1:0] dir2,
    input  [4:0] rand_x,
    input  [4:0] rand_y,
    input  [1:0] rand_type,

    output reg [383:0] s1x_bus, s1y_bus,
    output reg [383:0] s2x_bus, s2y_bus,
    output reg [6:0]   len1, len2,

    // 5 foods: packed as 5x5-bit x, 5x5-bit y, 5x2-bit type
    output reg [24:0] food_x_bus,   // food_x[i] = food_x_bus[i*5+:5]
    output reg [24:0] food_y_bus,
    output reg [9:0]  food_type_bus, // food_type[i] = food_type_bus[i*2+:2]

    output reg [6:0]  score1, score2,
    output reg [1:0]  mult1, mult2,
    output reg        dead1, dead2,
    output reg        game_over
);
    localparam GW = 32, GH = 23;   // match pixel_gen grid
    localparam NFOOD = 5;

    reg [5:0] s1x[0:63], s1y[0:63];
    reg [5:0] s2x[0:63], s2y[0:63];
    reg [3:0] streak1, streak2;

    // 5 food slots
    reg [4:0] fx[0:NFOOD-1];
    reg [4:0] fy[0:NFOOD-1];
    reg [1:0] ft[0:NFOOD-1];

    integer i, j;
    reg hit_wall1, hit_self1, hit_other1;
    reg hit_wall2, hit_self2, hit_other2;
    reg [5:0] nx1, ny1, nx2, ny2;
    reg eat1, eat2;
    reg [2:0] eat_idx1, eat_idx2;  // which food slot was eaten

    // Score for a food: bonus/speed/poison are FIXED, only normal uses mult
    function [6:0] get_points;
        input [1:0] ftype;
        input [1:0] mult;
        case (ftype)
            2'd0: get_points = (mult==2'd2) ? 3 : (mult==2'd1) ? 2 : 1; // x1/x2/x3
            2'd1: get_points = 7'd3;   // bonus: always +3
            2'd2: get_points = 7'd2;   // speed: always +2
            2'd3: get_points = 7'd0;   // poison: handled separately
            default: get_points = 7'd1;
        endcase
    endfunction

    // LFSR for per-slot respawn (use different taps per slot)
    reg [15:0] respawn_lfsr;
    always @(posedge game_clk or posedge rst) begin
        if (rst) respawn_lfsr <= 16'h1234;
        else respawn_lfsr <= {respawn_lfsr[14:0],
            respawn_lfsr[15]^respawn_lfsr[14]^respawn_lfsr[12]^respawn_lfsr[3]};
    end

    always @(posedge game_clk or posedge rst) begin
        if (rst) begin
            len1<=3; len2<=3;
            dead1<=0; dead2<=0; game_over<=0;
            score1<=0; score2<=0;
            mult1<=0; mult2<=0;
            streak1<=0; streak2<=0;

            for (i=0; i<64; i=i+1) begin
                s1x[i]<=6'd63; s1y[i]<=6'd63;
                s2x[i]<=6'd63; s2y[i]<=6'd63;
            end

            // P1: top-left quadrant, row 5, moving right
            s1x[0]<=5; s1y[0]<=5;
            s1x[1]<=4; s1y[1]<=5;
            s1x[2]<=3; s1y[2]<=5;

            // P2: bottom-right quadrant, row 17, moving left
            s2x[0]<=26; s2y[0]<=17;
            s2x[1]<=27; s2y[1]<=17;
            s2x[2]<=28; s2y[2]<=17;

            // Spread 5 foods across the map
            fx[0]<=5'd8;  fy[0]<=5'd4;  ft[0]<=2'd0;
            fx[1]<=5'd16; fy[1]<=5'd11; ft[1]<=2'd1;
            fx[2]<=5'd24; fy[2]<=5'd4;  ft[2]<=2'd0;
            fx[3]<=5'd8;  fy[3]<=5'd18; ft[3]<=2'd2;
            fx[4]<=5'd24; fy[4]<=5'd18; ft[4]<=2'd3;

        end else if (!game_over) begin

            nx1=s1x[0]; ny1=s1y[0];
            nx2=s2x[0]; ny2=s2y[0];

            if (!dead1) case(dir1)
                2'b00: ny1=s1y[0]-1; 2'b01: ny1=s1y[0]+1;
                2'b10: nx1=s1x[0]-1; 2'b11: nx1=s1x[0]+1;
            endcase
            if (!dead2) case(dir2)
                2'b00: ny2=s2y[0]-1; 2'b01: ny2=s2y[0]+1;
                2'b10: nx2=s2x[0]-1; 2'b11: nx2=s2x[0]+1;
            endcase

            hit_wall1=(nx1==0||nx1>=GW-1||ny1==0||ny1>=GH-1);
            hit_wall2=(nx2==0||nx2>=GW-1||ny2==0||ny2>=GH-1);
            hit_self1=0; hit_self2=0; hit_other1=0; hit_other2=0;

            for (i=1; i<64; i=i+1) begin
                if (i<len1 && s1x[i]==nx1 && s1y[i]==ny1) hit_self1=1;
                if (i<len2 && s2x[i]==nx2 && s2y[i]==ny2) hit_self2=1;
            end
            for (i=0; i<64; i=i+1) begin
                if (i<len2 && s2x[i]==nx1 && s2y[i]==ny1) hit_other1=1;
                if (i<len1 && s1x[i]==nx2 && s1y[i]==ny2) hit_other2=1;
            end
            if (nx1==nx2&&ny1==ny2) begin hit_other1=1; hit_other2=1; end

            if (!dead1&&(hit_wall1||hit_self1||hit_other1)) dead1<=1;
            if (!dead2&&(hit_wall2||hit_self2||hit_other2)) dead2<=1;
            if ((dead1||(hit_wall1||hit_self1||hit_other1))&&
                (dead2||(hit_wall2||hit_self2||hit_other2))) game_over<=1;

            // Check each food slot for collision
            eat1=0; eat2=0; eat_idx1=0; eat_idx2=0;
            for (j=0; j<NFOOD; j=j+1) begin
                if (!dead1&&!(hit_wall1||hit_self1||hit_other1)&&
                    nx1==fx[j]&&ny1==fy[j]) begin eat1=1; eat_idx1=j; end
                if (!dead2&&!(hit_wall2||hit_self2||hit_other2)&&
                    nx2==fx[j]&&ny2==fy[j]) begin eat2=1; eat_idx2=j; end
            end

            // Move P1
            if (!dead1&&!(hit_wall1||hit_self1||hit_other1)) begin
                for (i=63; i>0; i=i-1)
                    if (i<len1) begin s1x[i]<=s1x[i-1]; s1y[i]<=s1y[i-1]; end
                s1x[0]<=nx1; s1y[0]<=ny1;
                if (eat1 && ft[eat_idx1]!=2'd3 && len1<64) begin
                    len1<=len1+1;
                    s1x[len1]<=s1x[len1-1]; s1y[len1]<=s1y[len1-1];
                end
            end

            // Move P2
            if (!dead2&&!(hit_wall2||hit_self2||hit_other2)) begin
                for (i=63; i>0; i=i-1)
                    if (i<len2) begin s2x[i]<=s2x[i-1]; s2y[i]<=s2y[i-1]; end
                s2x[0]<=nx2; s2y[0]<=ny2;
                if (eat2 && ft[eat_idx2]!=2'd3 && len2<64) begin
                    len2<=len2+1;
                    s2x[len2]<=s2x[len2-1]; s2y[len2]<=s2y[len2-1];
                end
            end

            // Score P1
            if (eat1) begin
                if (ft[eat_idx1]==2'd3) begin
                    score1<=(score1>0)?score1-1:0;
                    streak1<=0; mult1<=0;
                end else begin
                    score1<=(score1+get_points(ft[eat_idx1],mult1)>99)?
                             99:score1+get_points(ft[eat_idx1],mult1);
                    streak1<=(streak1<15)?streak1+1:15;
                    mult1<=(streak1>=5)?2'd2:(streak1>=2)?2'd1:2'd0;
                end
                // Respawn eaten food slot
                fx[eat_idx1] <= (respawn_lfsr[9:5]%28)+2;
                fy[eat_idx1] <= (respawn_lfsr[15:11]%19)+2;
                ft[eat_idx1] <= rand_type;
            end

            // Score P2
            if (eat2 && !(eat1 && eat_idx2 == eat_idx1)) begin
                if (ft[eat_idx2]==2'd3) begin
                    score2<=(score2>0)?score2-1:0;
                    streak2<=0; mult2<=0;
                end else begin
                    score2<=(score2+get_points(ft[eat_idx2],mult2)>99)?
                             99:score2+get_points(ft[eat_idx2],mult2);
                    streak2<=(streak2<15)?streak2+1:15;
                    mult2<=(streak2>=5)?2'd2:(streak2>=2)?2'd1:2'd0;
                end
                fx[eat_idx2] <= (respawn_lfsr[4:0]%28)+2;
                fy[eat_idx2] <= (respawn_lfsr[10:6]%19)+2;
                ft[eat_idx2] <= rand_type ^ 2'd1;
            end
        end
    end

    // Flatten snake buses
    always @(*) begin
        for (i=0; i<64; i=i+1) begin
            s1x_bus[i*6+:6]=s1x[i]; s1y_bus[i*6+:6]=s1y[i];
            s2x_bus[i*6+:6]=s2x[i]; s2y_bus[i*6+:6]=s2y[i];
        end
        // Flatten food buses
        for (j=0; j<NFOOD; j=j+1) begin
            food_x_bus[j*5+:5]    = fx[j];
            food_y_bus[j*5+:5]    = fy[j];
            food_type_bus[j*2+:2] = ft[j];
        end
    end
endmodule