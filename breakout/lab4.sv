//`default_nettype none
module ChipInterface
  (input  logic        CLOCK_100,
   input  logic [ 3:0] BTN,
   input  logic [15:0] SW,
   output logic [ 3:0] D2_AN, D1_AN,
   output logic [ 7:0] D2_SEG, D1_SEG,
   output logic        HDMI_CLOCK_N, HDMI_CLOCK_P,
   output logic [ 2:0] HDMI_TX_P, HDMI_TX_N);

  // Signals for the clock wizard and HDMI IP
  logic clk_40MHz, clk_200MHz, locked;

  // Default signals
  logic reset;
  logic HS, VS, blank;
  logic [9:0] row, col;
  logic [7:0] red, green, blue;

  // Sync user inputs
  logic [3:0] btn_sync;
  Synchronizer #(4) btn_synchronizer (.clock(clk_40MHz), .async_in(BTN), .sync_out(btn_sync));
  assign reset = btn_sync[0];
  assign BTN1 = btn_sync[1];
  assign BTN2 = btn_sync[2];
  assign BTN3 = btn_sync[3];

  // MODULE INSTANTIATIONS

  // Colors
  logic [7:0] p_red, p_green, p_blue; // paddle
  logic [7:0] ba_red, ba_green, ba_blue; // ball
  logic [7:0] brick_red, brick_green, brick_blue; // bricks
  logic [7:0] w_red, w_green, w_blue; // wall
  logic [7:0] i_red, i_green, i_blue; // intermission
  // Color generation
  assign red = p_red | ba_red | brick_red | w_red | i_red;
  assign green = p_green | ba_green | brick_green | w_green | i_green;
  assign blue = p_blue | ba_blue | brick_blue | w_blue | i_blue;
  
  // Collision types
  logic brick_collision_top, wall_collision_top, paddle_collision_top,
  brick_collision_side, wall_collision_side, paddle_collision_side;

  // Other declarations
  logic restart, intermission, bricks_active;
  logic [9:0] col_ball, row_ball; // maybe remove
  logic [1:0] lives_left;

  // Game Clock
  logic game_clock;
  GameClock gc (.row, .col, .game_clock);

  // Score
  // note: inversion of DSEG output already done
  Score sc(.lives_left, .DSEG(D1_SEG));
  assign D2_SEG = 7'b111_1111; // set other display to 0

  // Wall
  Wall wa (.row, .col, .row_ball, .col_ball,
          .intermission, .bricks_active, .lives_left,
          .red(w_red), .green(w_green), .blue(w_blue),
          .top_collision(wall_collision_top),
          .side_collision(wall_collision_side));

  // Paddle
  Paddle pa (.row, .col, .row_ball, .col_ball, .BTN2, .BTN3,
            .clk_40MHz, .game_clock, .reset,
            .top_collision(paddle_collision_top), 
            .side_collision(paddle_collision_side), 
            .red(p_red), .green(p_green), .blue(p_blue));
            // missing outputs: col_left, col_max

  // Ball
  Ball ba (.row, .col, .clk_40MHz,
          .brick_collision_top, .wall_collision_top, .paddle_collision_top,
          .brick_collision_side, .wall_collision_side, .paddle_collision_side,
          .game_clock, .reset, .restart, .BTN1, .intermission,
            .col_ball, .row_ball, 
            .red(ba_red), .green(ba_green), .blue(ba_blue),
            .lives_left);

  // Intermission
  Intermission inter (.row, .col, .lives_left, .bricks_active, .BTN1,
                      .red(i_red), .green(i_green), .blue(i_blue), 
                      .active(intermission), .restart);  

  // Bricks
  Bricks bric (.row, .col, .col_ball, .row_ball,
              .game_clock, .clk_40MHz, .reset, .restart,
              .red(brick_red), .green(brick_green), .blue(brick_blue),
                .bricks_active, 
                .top_collision(brick_collision_top),
                .side_collision(brick_collision_side));

  // Test modules
  /* tester test(.row, .col, .red, .green, .blue); */  

  // Instantiate your TPG
  /*
  TestPatternGenerator tpg(
    .row,
    .col,
    .red,
    .green,
    .blue
   );*/

  // Instantiate your VGA module
  VGA vga(
    .clock_40MHz(clk_40MHz),
    .reset,
    .HS,
    .VS,
    .blank,
    .row,
    .col
   );

  //clock wizard configured with a 1x and 5x clock
  clk_wiz_0 clk_wiz (
    .clk_out1(clk_40MHz),
    .clk_out2(clk_200MHz),
    .reset(reset),
    .locked(locked),
    .clk_in1(CLOCK_100)
  );

  
  //Real Digital VGA to HDMI converter
  hdmi_tx_0 vga_to_hdmi (
    //Clocking and Reset
    .pix_clk(clk_40MHz),
    .pix_clkx5(clk_200MHz),
    .pix_clk_locked(locked),
    //Reset is active HIGH
    .rst(reset),

    //Color and Sync Signals
    .red(red),        // TODO: Connect your red channel
    .green(green),      // TODO: Connect your green channel
    .blue(blue),       // TODO: Connect your blue channel
    .hsync(HS),      // TODO: Connect your HS
    .vsync(VS),      // TODO: Connect your VS
    .vde(blank),        // TODO: Connect your blank signal

    //aux Data (unused)
    .aux0_din(4'b0),
    .aux1_din(4'b0),
    .aux2_din(4'b0),
    .ade(1'b0),

    //Differential outputs
    .TMDS_CLK_P(HDMI_CLOCK_P),          
    .TMDS_CLK_N(HDMI_CLOCK_N),          
    .TMDS_DATA_P(HDMI_TX_P),         
    .TMDS_DATA_N(HDMI_TX_N)          
  );

endmodule : ChipInterface
