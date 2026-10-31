//`default_nettype none

// Wall

/*
description:
Wall: The wall defines the limits of the court. It is made of three rectangular regions, each 30 pixels
wide. The left wall contains columns 10’d20 - 10’d49 and rows 10’d10 to 10’d589. The right
wall contains columns 10’d750- 10’d779 and the same rows. The top wall connects the two for
rows 10’d10- 10’d39. During play, the walls are grey colored (red, green and blue values set to
8’hCC.
*/

// For synchronizing the changes of the display modules (paddle, etc.)
// GameClock is 1 when the last pixel is display,
// it becomes 0 otherwise


// Note this implements an async reset
// Game clock used as an input to synchronize movement updates throughout
module GameClock
(input logic [9:0] row, col,
output logic game_clock);

always_comb begin
    case ({row, col})
        {10'd599, 10'd799}: game_clock = 1'b1;
        default: game_clock = 1'b0;
    endcase
end

endmodule

/*
ColorModule key:
Wall: 'd0
Paddle: 'd1
Ball: 'd2
Brick: 'd3
*/
module ColorModule
(input logic [2:0] module_type,
output logic [7:0] red, green, blue);

always_comb begin
    case (module_type)
        8'd0: begin // Wall
            red = 8'hCC;
            green = 8'hCC;
            blue = 8'hCC;
        end
        8'd1: begin // Paddle
            red = 8'b0;
            green = 8'hFF;
            blue = 8'b0;
        end
        default: begin
            red = 8'hFF;
            green = 8'b0;
            blue = 8'b0;
        end
    endcase
end

endmodule : ColorModule

module Wall
    (input logic [9:0] row, col, row_ball, col_ball,
    input logic intermission, bricks_active,
    input logic [1:0] lives_left,
    output logic [7:0] red, green, blue,
    output logic side_collision, top_collision);

    logic [7:0] redOn, greenOn, blueOn;
    ColorModule cm (.module_type('d0), .red(redOn), .green(greenOn), .blue(blueOn));

    // column ranges
    logic leftCol, rightCol, topCol;
    RangeCheck #(10) left_col (.val(col), .low(10'd20), .high(10'd49), .is_between(leftCol));
    RangeCheck #(10) right_col (.val(col), .low(10'd740), .high(10'd779), .is_between(rightCol));
    RangeCheck #(10) top_col (.val(col), .low(10'd20), .high(10'd779), .is_between(topCol));

    // row ranges
    logic sideRows, topRows;
    RangeCheck #(10) side_row (.val(row), .low(10'd10), .high(10'd589), .is_between(sideRows));
    RangeCheck #(10) top_row (.val(row), .low(10'd10), .high(10'd39), .is_between(topRows));

    logic inWall;
    assign inWall = (leftCol & sideRows) | (rightCol & sideRows) | (topCol & topRows);

    // win/lose state
    logic won, lost;
    assign won = ~bricks_active;
    assign lost = (lives_left == 2'd0);

    // Sets pixel outputs
    always_comb begin
        if (~inWall) begin
            red = 8'h00; green = 8'h00; blue = 8'h00;
        end
        else if (intermission & won) begin // green if won
            red = 8'h00; green = 8'hFF; blue = 8'h00;
        end
        else if (intermission & lost) begin // red if lost
            red = 8'hFF; green = 8'h00; blue = 8'h00;
        end
        else begin
            red = redOn; green = greenOn; blue = blueOn;
        end
    end

    // Combinational Collision Testing w/ ball
    logic hitLeft, hitRight;
    OffsetCheck #(10) lc (.val(10'd49), .low(col_ball - 10'd1), .delta(10'd6), .is_between(hitLeft));
    OffsetCheck #(10) rc (.val(10'd740), .low(col_ball), .delta(10'd6), .is_between(hitRight));
    OffsetCheck #(10) tc (.val(10'd39), .low(row_ball - 10'd2), .delta(10'd7), .is_between(top_collision));

    assign side_collision = hitLeft | hitRight;

endmodule : Wall


module Paddle
(input logic [9:0] row, col, row_ball, col_ball,
input logic BTN2, BTN3, clk_40MHz, game_clock, reset,
output logic [7:0] red, green, blue,
output logic [9:0] col_left, col_max,
output logic collision);

logic [7:0] redOn, greenOn, blueOn;
ColorModule cm(.module_type('d1), .red(redOn), .green(greenOn), .blue(blueOn));

logic valid_row, valid_col; // if paddle pixel is highlighted by row, col inputs

// generates valid_row, valid_col
OffsetCheck #(10) col_offset (.low(col_left), .delta(10'd79), .val(col), .is_between(valid_col));
RangeCheck #(10) row_offset (.low(10'd555), .high(10'd579), .val(row), .is_between(valid_row));

// Sets pixel outputs
assign red = (valid_row & valid_col) ? redOn : '0;
assign green = (valid_row & valid_col) ? greenOn : '0;
assign blue = (valid_row & valid_col) ? blueOn : '0;

// assign left col index
assign col_max = col_left + 10'd80;


// Combinational Collision Testing w/ ball
logic col_collision, row_collision;
OffsetCheck #(10) cc (.val(col_ball), .low(col_left - 10'd6), .delta(col_left + 10'd79 + 10'd6), .is_between(col_collision));
OffsetCheck #(10) rc (.val(row_ball), .low(10'd555 - 10'd6), .delta(10'd579 + 10'd5), .is_between(row_collision));
assign collision = col_collision & row_collision;


// POSITION UDPATES (PER GAME_CLOCK)
always_ff @(posedge clk_40MHz, posedge reset)
if (reset)
    col_left <= 10'd300; // arbitrarily chosen default col position
else if (game_clock) begin // clock tells paddle to update position
    // wall left ends at: 10'd49
    // wall right starts at: 10'd750
    // paddle moves left
    if (BTN2 & ~BTN3) begin
     if (col_left - 10'd8 <= 10'd49) // clips left wall
        col_left <= 10'd50;
    else
        col_left <= col_left - 10'd8; // shift left 8 pixels
        
    end
    // paddle moves right
    else if (BTN3 & ~BTN2) begin
        if (col_left + 10'd80 + 10'd8 >= 10'd750) // clips right wall
            col_left <= (10'd749 - 10'd80);
        else
            col_left <= col_left + 10'd8; // shift right 8 pixels
    end
    // no movement
    else begin
        col_left <= col_left;
    end

end
endmodule : Paddle


module Ball
(input logic [9:0] row, col,
input logic brick_collision, wall_collision, paddle_collision,
game_clock, clk_40MHz, reset, restart, BTN1, intermission,
output logic [9:0] col_ball, row_ball,
output logic [7:0] red, green, blue,
output logic [1:0] lives_left);

// Displaying ball on-screen
logic valid_col, valid_row; // check if col, row are valid
OffsetCheck #(10) col_offset (.val(col), .low(col_ball), .delta(10'd5), .is_between(valid_col));
OffsetCheck #(10) row_offset (.val(row), .low(row_ball), .delta(10'd5), .is_between(valid_row));
assign red = (valid_row & valid_col) ? 8'hFF : 8'h0;
assign green = (valid_row & valid_col) ? 8'hFF : 8'h0;
assign blue = (valid_row & valid_col) ? 8'hFF : 8'h0;

logic moving, right, up; // if ball is moving and moving right and up
// Determines if ball falls off-screen
logic death;
MagComp #(10) comp (.A(10'd599), .B(row_ball + 10'd6), .AltB(death));

// TOO LONG OF AN ALWAYS_FF? SIMPLIFY? + ALSO: CHECK IF BOUNCING IS CORRECT
always_ff @(posedge clk_40MHz, posedge reset) begin
// reset
if (reset | restart) begin
    col_ball <= 10'd400;
    row_ball <= 10'd420;
    moving <= 1'b0; // not moving
    lives_left <= 2'd3; // 3 lives left
    right <= 1'b0;
    up <= 1'b0;
end
else if (game_clock) begin
// intermission (i.e. game over)
if (intermission) begin
    moving <= 1'b0;
end
// BTN1 pressed -> start moving
else if (BTN1 & ~moving) begin
    moving <= 1'b1;
    col_ball <= col_ball + 10'd1;
    row_ball <= row_ball - 10'd2;
    right <= 1'b1;
    up <= 1'b1;
end
// Collision detected -> reverse direction
else if (brick_collision | wall_collision | paddle_collision) begin
    // flip directions
    if (right) begin // moving right
        col_ball <= col_ball - 10'd1;
        right <= 1'b0;
    end
    else begin // moving left
        col_ball <= col_ball + 10'd1;
        right <= 1'b1;
    end
    if (up) begin // moving up
        row_ball <= row_ball + 10'd2;
        up <= 1'b0;
    end
    else begin // moving down
        row_ball <= row_ball - 10'd2;
        up <= 1'b1;
    end
end
// Ball dies :(
else if (death) begin
    lives_left <= lives_left - 2'd1;
    col_ball <= 10'd400;
    row_ball <= 10'd420;
    moving <= 1'b0;
    right <= 1'b0;
    up <= 1'b0;
end
// regular movement
else begin
    if (right) // moving right
        col_ball <= col_ball + 10'd1;
    else // moving left
        col_ball <= col_ball - 10'd1;
    
    if (up) // moving up
        row_ball <= row_ball - 10'd2;
    else // moving down
        row_ball <= row_ball + 10'd2;
end
end
end
endmodule : Ball


// Module when game is over (either won, lost)
module Intermission
(input logic [9:0] row, col,
input logic [1:0] lives_left,
input logic bricks_active, BTN1,
output logic [7:0] red, green, blue,
output logic active, restart);

assign active = ~bricks_active | (lives_left == 2'b0);
assign restart = BTN1 & active;

// displays lost/won
// to implement

endmodule : Intermission

// x, y is the top left location of the ball
module Brick
#(parameter logic [9:0] TL_COL = 10'd0, TL_ROW = 10'd0,
            WIDTH = 10'd100, HEIGHT = 10'd30) // parameterize size
(input logic [9:0] row, col, col_ball, row_ball,
input logic game_clock, clk_40MHz, reset,
output logic collision, active, // check if outputs display correctly
input logic [7:0] redOn, greenOn, blueOn,
output logic [7:0] red, green, blue);

logic valid_col, valid_row; // check if col, row are valid

OffsetCheck #(10) col_offset (.val(col), .low(TL_COL), .delta(WIDTH - 1), .is_between(valid_col));
OffsetCheck #(10) row_offset (.val(row), .low(TL_ROW), .delta(HEIGHT - 1), .is_between(valid_row));

// assign colors if active
assign red = (valid_row & valid_col & active) ? redOn : '0;
assign green = (valid_row & valid_col & active) ? greenOn : '0;
assign blue = (valid_row & valid_col & active) ? blueOn : '0;


// Combinational Collision Testing w/ ball
logic col_collision, row_collision;
OffsetCheck #(10) cc (.val(col_ball), .low(TL_COL - 10'd6), .delta(TL_COL + WIDTH - 1 + 10'd6), .is_between(col_collision));
OffsetCheck #(10) rc (.val(row_ball), .low(TL_ROW - 10'd6), .delta(TL_ROW + HEIGHT - 1 + 10'd6), .is_between(row_collision));
assign collision = col_collision & row_collision & active;

always_ff @(posedge clk_40MHz, posedge reset)
if (reset)
    active <= 1'b1; // make active again
else if (game_clock) begin
    // if collision, then disable the Brick
    if (collision)
        active <= 1'b0; // disable if collision
    else
        active <= active; // keep active as is
end

endmodule : Brick

// Module instantiating and controlling all Bricks
module Bricks
(input logic [9:0] row, col, col_ball, row_ball,
input logic clk_40MHz, game_clock, reset, restart,
output logic [7:0] red, green, blue,
output logic bricks_active, collision);

logic [13:0] active_status;
logic [13:0] collision_status;
assign bricks_active = ~(active_status == 14'b0);
assign collision = ~(collision_status == 14'b0);

// Color assignments
logic [7:0] b0r, b1r, b2r, b3r, b4r, b5r, b6r, b7r, 
        b8r, b9r, b10r, b11r, b12r, b13r, b14r;
logic [7:0] b0g, b1g, b2g, b3g, b4g, b5g, b6g, b7g, 
        b8g, b9g, b10g, b11g, b12g, b13g, b14g;
logic [7:0] b0b, b1b, b2b, b3b, b4b, b5b, b6b, b7b, 
        b8b, b9b, b10b, b11b, b12b, b13b, b14b;

// NOTE: REPLACE WITH MULTIPLEXER?
// only one red will be selected
assign red = b0r | b1r | b2r | b3r | b4r | b5r | b6r | b7r
            | b8r | b9r | b10r | b11r | b12r | b13r | b14r;
assign green = b0g | b1g | b2g | b3g | b4g | b5g | b6g | b7g
            | b8g | b9g | b10g | b11g | b12g | b13g | b14g;
assign blue = b0b | b1b | b2b | b3b | b4b | b5b | b6b | b7b
            | b8b | b9b | b10b | b11b | b12b | b13b | b14b;

// top row
Brick #(70, 100, 100, 30) b0 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[0]), 
                                .active(active_status[0]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b0r), .green(b0g), .blue(b0b)); 
Brick #(170, 100, 100, 30) b1 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[1]), 
                                .active(active_status[1]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b1r), .green(b1g), .blue(b1b)); 
Brick #(270, 100, 100, 30) b2 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[2]), 
                                .active(active_status[2]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b2r), .green(b2g), .blue(b2b)); 
Brick #(370, 100, 100, 30) b3 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[3]), 
                                .active(active_status[3]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b3r), .green(b3g), .blue(b3b)); 
Brick #(470, 100, 100, 30) b4 (.row, .col, .col_ball, .row_ball, .game_clock,
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[4]), 
                                .active(active_status[4]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b4r), .green(b4g), .blue(b4b)); 
Brick #(570, 100, 100, 30) b5 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[5]), 
                                .active(active_status[5]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b5r), .green(b5g), .blue(b5b)); 
Brick #(670, 100, 50, 30) b6 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[6]), 
                                .active(active_status[6]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b6r), .green(b6g), .blue(b6b)); 

// 2nd row
Brick #(70, 150, 50, 30) b7 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[7]), 
                                .active(active_status[7]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b7r), .green(b7g), .blue(b7b)); 
Brick #(120, 150, 100, 30) b8 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[8]), 
                                .active(active_status[8]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b8r), .green(b8g), .blue(b8b)); 
Brick #(220, 150, 100, 30) b9 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[9]), 
                                .active(active_status[9]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b9r), .green(b9g), .blue(b9b)); 
Brick #(320, 150, 100, 30) b10 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[10]), 
                                .active(active_status[10]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b10r), .green(b10g), .blue(b10b)); 
Brick #(420, 150, 100, 30) b11 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[11]), 
                                .active(active_status[11]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b11r), .green(b11g), .blue(b11b)); 
Brick #(520, 150, 100, 30) b12 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[12]), 
                                .active(active_status[12]),
                                .redOn(8'hFF), 
                                .greenOn(8'hFF),
                                .blueOn(8'h00), 
                                .red(b12r), .green(b12g), .blue(b12b)); 
Brick #(620, 150, 100, 30) b13 (.row, .col, .col_ball, .row_ball, .game_clock, 
                                .clk_40MHz,
                                .reset(reset | restart), .collision(collision_status[13]), 
                                .active(active_status[13]),
                                .redOn(8'hFF), 
                                .greenOn(8'h00),
                                .blueOn(8'hFF), 
                                .red(b13r), .green(b13g), .blue(b13b)); 

endmodule : Bricks

module tester
(input logic [9:0] row, col,
output logic [7:0] red, green, blue);

always_comb begin
    if (col > 10'd500) begin
        red = 8'hFF;
        blue = 8'hFF;
        green = 8'hFF;
    end 
    else begin
        red = 8'h0;
        blue = 8'h0;
        green = 8'h0;
    end
end

endmodule : tester


module Synhcronizer 
    # (parameter WIDTH = 4)
    (input logic clock 
    input logic [WIDTH-1 : 0] async_in
    output logic [WIDTH-1 : 0] sync_out);

    logic [WIDTH-1:0] meta;

    always_ff @(posedge clock) begin
        meta <= async_in
        sync_out <= meta
    end
endmodule : Synhcronizer
