`default_nettype none


module VGA_test;
  logic clock_40MHz, reset, HS, VS, blank;
  logic [9:0] row, col;

  // h = clock within the row, v = row within the frame
  logic [10:0] h;
  logic [9:0] v;
  logic expHS, expVS, expBlank;
  logic [19:0] errors;

  VGA dut (.clock_40MHz, .reset, .HS, .VS, .blank, .row, .col);

  // clock
  initial begin
    clock_40MHz = 0;
    forever #10 clock_40MHz = ~clock_40MHz;
  end

  initial begin
    errors = 0;

    // reset so the VGA counters start at 0
    reset = 1;
    @(posedge clock_40MHz);
    #1 reset = 0;

    // go through every clock of one frame
    for (v = 0; v < 628; v++) begin
      for (h = 0; h < 1056; h++) begin

        // what the outputs should be at this spot
        expHS    = (h >= 128);
        expVS    = (v >= 4);
        expBlank = ~(h >= 216 && h <= 1015 && v >= 27 && v <= 626);

        // compare HS, VS, blank
        if (HS !== expHS || VS !== expVS || blank !== expBlank) begin
          errors++;
          if (errors < 10)
            $display("ERROR at v=%0d h=%0d: HS=%b VS=%b blank=%b",
                     v, h, HS, VS, blank);
        end

        // when on screen, also compare row and col
        if (~expBlank && (row !== v - 27 || col !== h - 216)) begin
          errors++;
          if (errors < 10)
            $display("ERROR at v=%0d h=%0d: row=%0d col=%0d", v, h, row, col);
        end

        // next clock
        @(posedge clock_40MHz);
        #1;
      end
    end

    $display("VGA test done: %0d errors", errors);
    $finish;

  end
endmodule : VGA_test

module Ball_Test();
    logic [9:0] row, col, col_ball, row_ball;
    logic brick_collision_top, wall_collision_top, paddle_collision_top;
    logic brick_collision_side, wall_collision_side, paddle_collision_side;
    logic game_clock, clk_40MHz, reset, restart, BTN1, intermission;
    logic [7:0] red, green, blue;
    logic [1:0] lives_left;
    logic [7:0] counter;

    Ball dut (.row, .col, .brick_collision_top, .wall_collision_top,
              .paddle_collision_top, .brick_collision_side,
              .wall_collision_side, .paddle_collision_side, .game_clock,
              .clk_40MHz, .reset, .restart, .BTN1, .intermission,
              .col_ball, .row_ball, .red, .green, .blue, .lives_left);

    initial begin
        clk_40MHz = 0;
        forever #5 clk_40MHz = ~clk_40MHz;
    end

    initial begin
        $monitor($time,, "ball:(%d, %d), lives:%d, up:%b, right:%b, red:%h",
        col_ball, row_ball, lives_left, dut.up, dut.right, red);

        row = 10'd420; col = 10'd400; // pixel at ball start
        brick_collision_top = 0; wall_collision_top = 0; paddle_collision_top = 0;
        brick_collision_side = 0; wall_collision_side = 0; paddle_collision_side = 0;
        restart = 0; BTN1 = 0; intermission = 0;
        game_clock = 1; // every clock is a game tick
        reset = 1;

        @(posedge clk_40MHz);
        reset <= 0;
        @(posedge clk_40MHz); // no BTN1, should stay at (400, 420)

        BTN1 <= 1;
        @(posedge clk_40MHz); // serve, (401, 418)
        BTN1 <= 0;
        @(posedge clk_40MHz); // moving, (402, 416)

        wall_collision_top <= 1;
        @(posedge clk_40MHz); // bounce down, (403, 418)
        wall_collision_top <= 0;

        wall_collision_side <= 1;
        @(posedge clk_40MHz); // bounce left, (402, 420)
        wall_collision_side <= 0;

        // fall to bottom, lose a life
        for (counter = 8'd0; counter < 8'd88; counter++) begin
            @(posedge clk_40MHz);
        end

        intermission <= 1; BTN1 <= 1;
        @(posedge clk_40MHz); // game over, should not serve
        intermission <= 0; BTN1 <= 0;

        restart <= 1;
        @(posedge clk_40MHz); // lives back to 3
        restart <= 0;

        #10 $finish;
    end

endmodule : Ball_Test

module Paddle_Test();
    logic [9:0] row, col, row_ball, col_ball, col_left, col_max;
    logic BTN2, BTN3, clk_40MHz, game_clock, reset;
    logic [7:0] red, green, blue;
    logic top_collision, side_collision;
    logic [7:0] counter;

    Paddle dut (.row, .col, .row_ball, .col_ball, .BTN2, .BTN3,
                .clk_40MHz, .game_clock, .reset, .red, .green, .blue,
                .col_left, .col_max, .top_collision, .side_collision);

    initial begin
        clk_40MHz = 0;
        forever #5 clk_40MHz = ~clk_40MHz;
    end

    initial begin
        $monitor($time,, "col_left:%d, top:%b, side:%b, green:%h",
        col_left, top_collision, side_collision, green);

        row = 10'd0; col = 10'd0; row_ball = 10'd400; col_ball = 10'd400;
        BTN2 = 0; BTN3 = 0;
        game_clock = 1; // every clock is a game tick
        reset = 1;

        @(posedge clk_40MHz);
        reset <= 0; // col_left = 300

        BTN2 <= 1;
        @(posedge clk_40MHz); // left, 292
        BTN2 <= 0; BTN3 <= 1;
        @(posedge clk_40MHz); // right, 300
        BTN2 <= 1;
        @(posedge clk_40MHz); // both, stays 300
        BTN2 <= 0; BTN3 <= 0;
        @(posedge clk_40MHz); // neither, stays 300

        // hold left until it hits the wall
        BTN2 <= 1;
        for (counter = 8'd0; counter < 8'd40; counter++) begin
            @(posedge clk_40MHz);
        end
        BTN2 <= 0;

        // hold right until it hits the wall
        BTN3 <= 1;
        for (counter = 8'd0; counter < 8'd90; counter++) begin
            @(posedge clk_40MHz);
        end
        BTN3 <= 0;
        @(posedge clk_40MHz);

        #10 row_ball = 10'd549; col_ball = 10'd700; // ball on top, top = 1
        #10 row_ball = 10'd560; col_ball = 10'd663; // ball on left side, side = 1
        #10 row_ball = 10'd400; col_ball = 10'd400; // far away, both 0
        #10 row = 10'd560; col = 10'd700;
        #10 row = 10'd560; col = 10'd100; 
        #10 $finish;
    end

endmodule : Paddle_Test


module Brick_Test();
    logic [9:0] row, col, col_ball, row_ball;
    logic game_clock, clk_40MHz, reset, restart;
    logic top_collision, side_collision, active;
    logic [7:0] red, green, blue;

    Brick #(70, 100, 100, 30) dut (.row, .col, .col_ball, .row_ball,
                                   .game_clock, .clk_40MHz, .reset, .restart,
                                   .top_collision, .side_collision, .active,
                                   .redOn(8'hFF), .greenOn(8'hFF), .blueOn(8'h00),
                                   .red, .green, .blue);

    initial begin
        clk_40MHz = 0;
        forever #5 clk_40MHz = ~clk_40MHz;
    end

    initial begin
        $monitor($time,, "active:%b, top:%b, side:%b, red:%h, green:%h",
        active, top_collision, side_collision, red, green);

        row = 10'd0; col = 10'd0; row_ball = 10'd400; col_ball = 10'd400;
        game_clock = 0; restart = 0;
        reset = 1;

        @(posedge clk_40MHz);
        reset <= 0;

        #10 row = 10'd110; col = 10'd100; // inside brick
        #10 row = 10'd110; col = 10'd200; // outside brick
        #10 row_ball = 10'd110; col_ball = 10'd64; // hits side
        #10 row_ball = 10'd130; col_ball = 10'd100; // hits bottom
        #10 row = 10'd110; col = 10'd100; // back inside

        @(posedge clk_40MHz);
        game_clock <= 1;
        @(posedge clk_40MHz); // brick breaks
        game_clock <= 0;

        @(posedge clk_40MHz);
        restart <= 1; game_clock <= 1;
        @(posedge clk_40MHz); // brick comes back
        restart <= 0; game_clock <= 0;

        #10 $finish;
    end

endmodule : Brick_Test

module Wall_Test();
    logic [9:0] row, col, row_ball, col_ball;
    logic intermission, bricks_active;
    logic [1:0] lives_left;
    logic [7:0] red, green, blue;
    logic side_collision, top_collision;

    Wall dut (.row, .col, .row_ball, .col_ball, .intermission,
              .bricks_active, .lives_left, .red, .green, .blue,
              .side_collision, .top_collision);

    initial begin
        $monitor($time,, "side:%b, top:%b, red:%h, green:%h, blue:%h",
        side_collision, top_collision, red, green, blue);

        intermission = 0; bricks_active = 1; lives_left = 2'd3;
        row = 10'd300; col = 10'd400; // middle
        row_ball = 10'd300; col_ball = 10'd400;

        #10 col = 10'd30; // left wall
        #10 col = 10'd760; // right wall
        #10 row = 10'd20; col = 10'd400; // top wall
        #10 row = 10'd595; col = 10'd30; // below wall, should be black

        #10 col_ball = 10'd50; // hits left
        #10 col_ball = 10'd744; // hits right
        #10 col_ball = 10'd400; row_ball = 10'd40; // hits top
        #10 row_ball = 10'd41; // still top
        #10 row_ball = 10'd100; // no hit

        #10 row = 10'd300; col = 10'd30;
        #10 intermission = 1; bricks_active = 0; // won
        #10 bricks_active = 1; lives_left = 2'd0; // lost
        #10 $finish;
    end

endmodule : Wall_Test



module RangeCheck_Test();
    logic [3:0] high, low, val;
    logic           is_between;

    RangeCheck #(.WIDTH(4)) dut (.high, .low, .val, .is_between);

    initial begin
        $monitor($time,, "low:%d, high:%d, val:%d, is_between:%b", 
        low, high, val, is_between);

        low = 4'd3; high = 4'd8; val = 4'd3; // low edge isbetween
        #10 val = 4'd8; // high edge still isbetween
        #10 val = 4'd2; // out of range (low)
        #10 val = 4'd9; // out of range (high)
        #10 val = 4'd0; // out of range(low)
        #10 low = 4'd3; high = 4'd3; val = 4'd3; // within range
        #10 val = 4'd4;
        #10 val = 4'd2;
        #10 $finish;
    end

endmodule : RangeCheck_Test


module OffsetCheck_test();
  logic [3:0] delta, low, val;
  logic       is_between;

  OffsetCheck #(.WIDTH(4)) dut (.delta, .low, .val, .is_between);

  initial begin
    $monitor($time,, "low:%d delta:%d val:%d is_between:%b",
             low, delta, val, is_between);

    low = 4'd3; delta = 4'd5; val = 4'd3;  // low edge.. inside
    #10 val = 4'd8;                        // low + delta edge.. inside
    #10 val = 4'd5;                        // middle.. inside
    #10 val = 4'd2;                        //  below
    #10 val = 4'd9;                        //  above
    #10 val = 4'd0;                        // well below
    #10 delta = 4'd0; val = 4'd3;          // zero offset.. inside
    #10 val = 4'd4;                        // zero offset.. outside
    #10 low = 4'd10; delta = 4'd5; val = 4'd15;  // sum hits max.. inside
    #10 val = 4'd9;                        // just below
    #10 $finish;
  end
endmodule: OffsetCheck_test 
        