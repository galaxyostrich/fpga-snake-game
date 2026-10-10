`timescale 1ns / 1ps
// vga_pixel_gen.v  -  800x600 renderer


module vga_pixel_gen(
    input  clk40,
    input  [10:0] hpos,
    input  [9:0]  vpos,
    input  display_on,
    input  [383:0] s1x_bus, s1y_bus,
    input  [6:0]   len1,
    input  [383:0] s2x_bus, s2y_bus,
    input  [6:0]   len2,
    input  [24:0]  food_x_bus, food_y_bus,
    input  [9:0]   food_type_bus,
    input  [6:0]   score1, score2,
    input  [1:0]   mult1, mult2,
    input          dead1, dead2,
    input          game_over,
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b
);
    localparam HUD_H  = 36;
    localparam CELL_W = 25;
    localparam CELL_H = 24;
    localparam GW     = 32;
    localparam GH     = 23;

    wire in_hud  = (vpos < HUD_H) && display_on;
    wire in_grid = (vpos >= HUD_H) && (vpos < HUD_H + GH*CELL_H) && display_on;

    wire [5:0] gx = hpos / CELL_W;
    wire [5:0] gy = (vpos >= HUD_H) ? ((vpos - HUD_H) / CELL_H) : 6'd0;
    wire [4:0] px = hpos % CELL_W;
    wire [4:0] py = (vpos >= HUD_H) ? ((vpos - HUD_H) % CELL_H) : 5'd0;
    wire cell_border = (px==0)||(py==0);

    wire signed [5:0] fdx = px - 12;
    wire signed [5:0] fdy = py - 11;
    wire [4:0] fadx = fdx[5] ? -fdx : fdx;
    wire [4:0] fady = fdy[5] ? -fdy : fdy;
    wire [9:0] dist2 = fdx*fdx + fdy*fdy;
    wire food_circle  = (dist2 < 50);
    wire food_diamond = ((fadx+fady) <= 8);
    wire food_plus    = ((fadx<=2&&fady<=7)||(fady<=2&&fadx<=7));
    wire food_xshape  = ((fadx==fady&&fadx<=6)||(fadx+fady==7&&fadx<=6));

    function [23:0] digit_bmp;
        input [3:0] d;
        case(d)
            4'd0: digit_bmp=24'b0110_1001_1001_1001_1001_0110;
            4'd1: digit_bmp=24'b0010_0110_0010_0010_0010_0111;
            4'd2: digit_bmp=24'b0110_1001_0001_0110_1000_1111;
            4'd3: digit_bmp=24'b1110_0001_0110_0001_0001_1110;
            4'd4: digit_bmp=24'b0001_0101_1001_1111_0001_0001;
            4'd5: digit_bmp=24'b1111_1000_1110_0001_1001_0110;
            4'd6: digit_bmp=24'b0110_1000_1110_1001_1001_0110;
            4'd7: digit_bmp=24'b1111_0001_0010_0100_0100_0100;
            4'd8: digit_bmp=24'b0110_1001_0110_1001_1001_0110;
            4'd9: digit_bmp=24'b0110_1001_0111_0001_1001_0110;
            default: digit_bmp=24'b0;
        endcase
    endfunction

    function letter_pixel;
        input [10:0] hx, bx;
        input [9:0]  hy, by;
        input [7:0]  ch;   // ASCII-like code
        reg [10:0] lx;
        reg [9:0]  ly;
        begin
            lx = hx - bx;
            ly = hy - by;
            letter_pixel = 0;

            if (lx < 5 && ly < 7) begin
                case (ch)

                "G": letter_pixel = (ly==0&&lx>0&&lx<4)||
                                    (ly==1&&lx==0)||(ly==1&&lx==4)||
                                    (ly==2&&lx==0)||
                                    (ly==3&&(lx==0||lx>=2))||
                                    (ly==4&&(lx==0||lx==4))||
                                    (ly==5&&(lx==0||lx==4))||
                                    (ly==6&&lx>0&&lx<4);

                "A": letter_pixel = (ly==0&&lx>0&&lx<4)||
                                    (ly==1&&(lx==0||lx==4))||
                                    (ly==2&&(lx==0||lx==4))||
                                    (ly==3&&lx<5)||
                                    (ly>=4&&(lx==0||lx==4));

                "M": letter_pixel = (lx==0||lx==4)||
                                    (ly==1&&(lx==1||lx==3))||
                                    (ly==2&&lx==2);

                "E": letter_pixel = (lx==0)||
                                    (ly==0||ly==3||ly==6);

                "O": letter_pixel = (ly==0||ly==6)&&(lx>0&&lx<4)||
                                    (lx==0||lx==4)&&(ly>0&&ly<6);

                "V": letter_pixel = (ly<5&&(lx==0||lx==4))||
                                    (ly==5&&(lx==1||lx==3))||
                                    (ly==6&&lx==2);

                "R": letter_pixel = (lx==0)||
                                    (ly==0&&lx<4)||
                                    (ly==3&&lx<4)||
                                    (lx==4&&ly<3)||
                                    (lx==ly-1&&ly>3);
                
                "W": letter_pixel = (lx==0||lx==4) ||
                                    (ly==5&&(lx==1||lx==3)) ||
                                    (ly==6&&lx==2);

                "I": letter_pixel = (ly==0||ly==6)||(lx==2);

                "N": letter_pixel = (lx==0||lx==4)||
                                    (lx==ly && ly<5);

                "D": letter_pixel = (lx==0)||
                                    (ly==0&&lx<4)||
                                    (ly==6&&lx<4)||
                                    (lx==4&&ly>0&&ly<6);

                "P": letter_pixel = (lx==0) || 
                                    (ly==0&&lx<4) || 
                                    (ly==3&&lx<4) || 
                                    ((ly==1||ly==2)&&lx==4);

                "S": letter_pixel = (ly==0&&lx>0) || 
                                    (lx==0&&(ly==1||ly==2)) || 
                                    (ly==3&&lx>0&&lx<4) || 
                                    (lx==4&&(ly==4||ly==5)) || 
                                    (ly==6&&lx<4);

                "B": letter_pixel = (lx==0) || 
                                    ((ly==0||ly==3||ly==6)&&lx<4) || 
                                    (lx==4&&(ly!=0&&ly!=3&&ly!=6));

                "T": letter_pixel = (ly==0) || (lx==2);

                "C": letter_pixel = ((ly==0||ly==6)&&lx>0) || 
                                    (lx==0&&ly>0&&ly<6);

                default: letter_pixel = 0;
                endcase
            end
        end
    endfunction

    function digit_pixel;
        input [10:0] hx, bx; input [9:0] hy, by;
        input [3:0] tens, ones;
        reg [10:0] lx; reg [9:0] ly;
        reg [23:0] bmp; reg [3:0] row;
        begin
            lx=hx-bx; ly=hy-by; digit_pixel=0;
            if(ly<6&&lx<9) begin
                if(lx<4) begin bmp=digit_bmp(tens); row=bmp[23-ly*4-:4]; digit_pixel=row[3-lx]; end
                else if(lx>4) begin bmp=digit_bmp(ones); row=bmp[23-ly*4-:4]; digit_pixel=row[3-(lx-5)]; end
            end
        end
    endfunction

    function mult_pixel;
        input [10:0] hx, bx; input [9:0] hy, by; input [1:0] mult;
        reg [10:0] lx; reg [9:0] ly; reg [3:0] d; reg [23:0] bmp; reg [3:0] row;
        begin
            lx=hx-bx; ly=hy-by; mult_pixel=0;
            if(ly<6&&lx<9) begin
                if(lx<4) mult_pixel=((ly==0||ly==5)&&(lx==0||lx==3))||((ly>=1&&ly<=4)&&(lx==1||lx==2));
                else if(lx>4) begin
                    d=(mult==2'd2)?4'd3:(mult==2'd1)?4'd2:4'd1;
                    bmp=digit_bmp(d); row=bmp[23-ly*4-:4]; mult_pixel=row[3-(lx-5)];
                end
            end
        end
    endfunction

    function label_pixel;
        input [10:0] hx, bx; input [9:0] hy, by; input is_p2;
        reg [10:0] lx, cx; reg [9:0] ly;
        begin
            lx=hx-bx; ly=hy-by; label_pixel=0;
            if(ly<6&&lx<11) begin
                if(lx<5) case(ly)
                    0: label_pixel=(lx<4); 1: label_pixel=(lx==0||lx==4);
                    2: label_pixel=(lx<4); 3: label_pixel=(lx==0);
                    4: label_pixel=(lx==0); 5: label_pixel=(lx==0);
                    default: label_pixel=0;
                endcase
                else if(lx>5) begin
                    cx=lx-6;
                    if(!is_p2) case(ly)
                        0: label_pixel=(cx==1); 1: label_pixel=(cx==0||cx==1);
                        2: label_pixel=(cx==1); 3: label_pixel=(cx==1);
                        4: label_pixel=(cx==1); 5: label_pixel=(cx<4);
                        default: label_pixel=0;
                    endcase
                    else case(ly)
                        0: label_pixel=(cx==0||cx==1||cx==2); 1: label_pixel=(cx==3);
                        2: label_pixel=(cx==1||cx==2); 3: label_pixel=(cx==0);
                        4: label_pixel=(cx==0); 5: label_pixel=(cx<4);
                        default: label_pixel=0;
                    endcase
                end
            end
        end
    endfunction

    // Single cell fill check for game-over snake rendering
    function [1:0] go_cell;
        input [10:0] hx; input [9:0] hy;
        input [5:0] gsx, gsy;
        reg [10:0] x0; reg [9:0] y0;
        reg [4:0] lpx, lpy;
        begin
            x0=gsx*CELL_W; y0=gsy*CELL_H+HUD_H; go_cell=0;
            if(hx>=x0&&hx<x0+CELL_W&&hy>=y0&&hy<y0+CELL_H) begin
                lpx=hx-x0; lpy=hy-y0;
                if(lpx>0&&lpx<CELL_W-1&&lpy>0&&lpy<CELL_H-1) go_cell=2;
                else go_cell=1;
            end
        end
    endfunction

    // Colors
    localparam C_BLACK  = 12'h000;
    localparam C_BG     = 12'h001;
    localparam C_HUD_BG = 12'h001;
    localparam C_HUD_LN = 12'h336;
    localparam C_WALL   = 12'h335;
    localparam C_P1     = 12'h0EE;
    localparam C_P1H    = 12'h0BB;
    localparam C_P1D    = 12'h044;
    localparam C_P1_HUD = 12'h0CC;
    localparam C_P2     = 12'hEE0;
    localparam C_P2H    = 12'hBB0;
    localparam C_P2D    = 12'h440;
    localparam C_P2_HUD = 12'hCC0;
    localparam C_FOOD_N = 12'hF44;
    localparam C_FOOD_B = 12'hFD0;
    localparam C_FOOD_S = 12'h55F;
    localparam C_FOOD_P = 12'hA3F;

    wire [3:0] s1t=score1/10, s1o=score1%10;
    wire [3:0] s2t=score2/10, s2o=score2%10;

    wire p1_wins = game_over && (score1 > score2);
    wire p2_wins = game_over && (score2 > score1);
    wire its_tie = game_over && (score1 == score2);

    wire in_result_text;

    assign in_result_text =
        p1_wins ? (
            label_pixel(hpos/3, 339/3, vpos/3, 264/3, 0) || // P1
            letter_pixel(hpos/3, 384/3, vpos/3, 264/3, "W") ||
            letter_pixel(hpos/3, 414/3, vpos/3, 264/3, "I") ||
            letter_pixel(hpos/3, 444/3, vpos/3, 264/3, "N")
        ) :
        p2_wins ? (
            label_pixel(hpos/3, 339/3, vpos/3, 264/3, 1) || // P2
            letter_pixel(hpos/3, 384/3, vpos/3, 264/3, "W") ||
            letter_pixel(hpos/3, 414/3, vpos/3, 264/3, "I") ||
            letter_pixel(hpos/3, 444/3, vpos/3, 264/3, "N")
        ) :
        its_tie ? (
            letter_pixel(hpos/3, 348/3, vpos/3, 264/3, "D") ||
            letter_pixel(hpos/3, 378/3, vpos/3, 264/3, "R") ||
            letter_pixel(hpos/3, 408/3, vpos/3, 264/3, "A") ||
            letter_pixel(hpos/3, 438/3, vpos/3, 264/3, "W")
        ) : 1'b0;

    wire in_gameover_text =
        letter_pixel(hpos/4, 220/4, vpos/4, 200/4, "G") ||
        letter_pixel(hpos/4, 260/4, vpos/4, 200/4, "A") ||
        letter_pixel(hpos/4, 300/4, vpos/4, 200/4, "M") ||
        letter_pixel(hpos/4, 340/4, vpos/4, 200/4, "E") ||

        letter_pixel(hpos/4, 420/4, vpos/4, 200/4, "O") ||
        letter_pixel(hpos/4, 460/4, vpos/4, 200/4, "V") ||
        letter_pixel(hpos/4, 500/4, vpos/4, 200/4, "E") ||
        letter_pixel(hpos/4, 540/4, vpos/4, 200/4, "R");

    wire in_restart_text =
        letter_pixel(hpos/2, 137, vpos/2, 250, "P") ||
        letter_pixel(hpos/2, 143, vpos/2, 250, "R") ||
        letter_pixel(hpos/2, 149, vpos/2, 250, "E") ||
        letter_pixel(hpos/2, 155, vpos/2, 250, "S") ||
        letter_pixel(hpos/2, 161, vpos/2, 250, "S") ||
        
        letter_pixel(hpos/2, 173, vpos/2, 250, "B") ||
        letter_pixel(hpos/2, 179, vpos/2, 250, "T") ||
        letter_pixel(hpos/2, 185, vpos/2, 250, "N") ||
        letter_pixel(hpos/2, 191, vpos/2, 250, "C") ||
        
        letter_pixel(hpos/2, 203, vpos/2, 250, "T") ||
        letter_pixel(hpos/2, 209, vpos/2, 250, "O") ||
        
        letter_pixel(hpos/2, 221, vpos/2, 250, "R") ||
        letter_pixel(hpos/2, 227, vpos/2, 250, "E") ||
        letter_pixel(hpos/2, 233, vpos/2, 250, "S") ||
        letter_pixel(hpos/2, 239, vpos/2, 250, "T") ||
        letter_pixel(hpos/2, 245, vpos/2, 250, "A") ||
        letter_pixel(hpos/2, 251, vpos/2, 250, "R") ||
        letter_pixel(hpos/2, 257, vpos/2, 250, "T");

    // Game-over snake positions
    // P1: head gx=4,gy=9 body extends right to gx=8
    // P2: head gx=27,gy=9 body extends left to gx=23
    localparam P1_HX = 4;
    localparam P1_HY = 9;
    localparam P2_HX = 27;
    localparam P2_HY = 9;

    // Crown centers (above head top edge)

    // Score pixel positions: 3x-scaled digits below snake (each scaled pixel = 3px)
    // Font is 9px wide x 6px tall -> scaled to 27px x 18px
    // Center under body midpoint
    localparam P1_SX = (P1_HX + 2)*CELL_W - 4;
    localparam P1_SY = (P1_HY + 2)*CELL_H + HUD_H + 6;
    localparam P2_SX = (P2_HX - 2)*CELL_W - 4;
    localparam P2_SY = (P2_HY + 2)*CELL_H + HUD_H + 6;

    integer i, j;
    reg hit1, hit2, is_head1, is_head2;
    reg [5:0] sx, sy;
    reg food_hit; reg [1:0] food_hit_type;
    reg [1:0] gop1, gop2;
    reg gop1h, gop2h;
    reg in_s1, in_s2;
    reg [11:0] color;

    always @(*) begin
        hit1=0; hit2=0; is_head1=0; is_head2=0;
        for(i=0;i<64;i=i+1) begin
            sx=s1x_bus[i*6+:6]; sy=s1y_bus[i*6+:6];
            if(i<len1&&in_grid&&gx==sx&&gy==sy) begin hit1=1; if(i==0)is_head1=1; end
            sx=s2x_bus[i*6+:6]; sy=s2y_bus[i*6+:6];
            if(i<len2&&in_grid&&gx==sx&&gy==sy) begin hit2=1; if(i==0)is_head2=1; end
        end
        food_hit=0; food_hit_type=0;
        for(j=0;j<5;j=j+1)
            if(in_grid&&gx==food_x_bus[j*5+:5]&&gy==food_y_bus[j*5+:5])
                begin food_hit=1; food_hit_type=food_type_bus[j*2+:2]; end

        // Game-over snake body cells
        gop1 = go_cell(hpos,vpos,P1_HX,  P1_HY) | go_cell(hpos,vpos,P1_HX+1,P1_HY) |
               go_cell(hpos,vpos,P1_HX+2,P1_HY) | go_cell(hpos,vpos,P1_HX+3,P1_HY) |
               go_cell(hpos,vpos,P1_HX+4,P1_HY);
        gop1h = (go_cell(hpos,vpos,P1_HX,P1_HY) != 0);

        gop2 = go_cell(hpos,vpos,P2_HX,  P2_HY) | go_cell(hpos,vpos,P2_HX-1,P2_HY) |
               go_cell(hpos,vpos,P2_HX-2,P2_HY) | go_cell(hpos,vpos,P2_HX-3,P2_HY) |
               go_cell(hpos,vpos,P2_HX-4,P2_HY);
        gop2h = (go_cell(hpos,vpos,P2_HX,P2_HY) != 0);


        // Score pixels: 3x magnified font lookup
        in_s1 = display_on && (vpos >= P1_SY) && (vpos < P1_SY+18) &&
                (hpos >= P1_SX) && (hpos < P1_SX+27) &&
                digit_pixel(hpos/3, P1_SX/3, vpos/3, P1_SY/3, s1t, s1o);
        in_s2 = display_on && (vpos >= P2_SY) && (vpos < P2_SY+18) &&
                (hpos >= P2_SX) && (hpos < P2_SX+27) &&
                digit_pixel(hpos/3, P2_SX/3, vpos/3, P2_SY/3, s2t, s2o);

        color = C_BLACK;

        if(!display_on) begin
            color = C_BLACK;

        end else if(game_over) begin
            color = C_BG;
            if(gop1 == 2)   color = gop1h ? C_P1H : C_P1;
            else if(gop2 == 2)   color = gop2h ? C_P2H : C_P2;
            else if(in_s1)       color = p1_wins ? C_P1_HUD : 12'hAAA;
            else if(in_s2)       color = p2_wins ? C_P2_HUD : 12'hAAA;
            else if(in_gameover_text)  color = 12'hFFF;
            else if(in_result_text)    color = 12'hFFF;
            else if(in_restart_text)   color = 12'hFFF;

        end else if(in_hud) begin
            color = C_HUD_BG;
            if     (vpos==HUD_H-1)                         color = C_HUD_LN;
            else if(hpos<6)                                  color = C_P1;
            else if(hpos>=794)                               color = C_P2;
            else if(hpos>=10&&hpos<21&&vpos>=15&&vpos<21&&
                    label_pixel(hpos,10,vpos,15,0))          color = C_P1_HUD;
            else if(hpos>=75&&hpos<84&&vpos>=15&&vpos<21&&
                    digit_pixel(hpos,75,vpos,15,s1t,s1o))    color = C_P1_HUD;
            else if(hpos>=90&&hpos<99&&vpos>=15&&vpos<21&&
                    mult_pixel(hpos,90,vpos,15,mult1))
                color=(mult1==2'd2)?12'hF80:(mult1==2'd1)?12'hFF8:C_P1_HUD;
            else if(vpos>=17&&vpos<=19&&hpos>=350&&hpos<=450)
                color=(hpos%20==0)?12'h446:C_HUD_BG;
            else if(hpos>=700&&hpos<709&&vpos>=15&&vpos<21&&
                    mult_pixel(hpos,700,vpos,15,mult2))
                color=(mult2==2'd2)?12'hF80:(mult2==2'd1)?12'hFF8:C_P2_HUD;
            else if(hpos>=714&&hpos<723&&vpos>=15&&vpos<21&&
                    digit_pixel(hpos,714,vpos,15,s2t,s2o))   color = C_P2_HUD;
            else if(hpos>=768&&hpos<779&&vpos>=15&&vpos<21&&
                    label_pixel(hpos,768,vpos,15,1))          color = C_P2_HUD;

        end else if(!in_grid) begin
            color = C_BG;

        end else begin
            if(gx==0||gx==GW-1||gy==0||gy==GH-1) color=C_WALL;
            else if(food_hit) case(food_hit_type)
                2'd0: color=food_circle  ? C_FOOD_N : C_BG;
                2'd1: color=food_diamond ? C_FOOD_B : C_BG;
                2'd2: color=food_plus    ? C_FOOD_S : C_BG;
                2'd3: color=food_xshape  ? C_FOOD_P : C_BG;
                default: color=C_BG;
            endcase
            else if(hit1) begin
                if(dead1) color=cell_border?C_BG:C_P1D;
                else if(is_head1) begin
                    if((px==18&&py==6)||(px==18&&py==14)) color=C_BLACK;
                    else color=cell_border?C_BG:C_P1H;
                end else color=cell_border?C_BG:C_P1;
            end else if(hit2) begin
                if(dead2) color=cell_border?C_BG:C_P2D;
                else if(is_head2) begin
                    if((px==4&&py==6)||(px==4&&py==14)) color=C_BLACK;
                    else color=cell_border?C_BG:C_P2H;
                end else color=cell_border?C_BG:C_P2;
            end else color=C_BG;
        end

        vga_r=color[11:8];
        vga_g=color[7:4];
        vga_b=color[3:0];
    end
endmodule