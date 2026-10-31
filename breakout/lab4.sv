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

  // Define your signals here
  logic reset;
  logic HS, VS, blank;
  logic [9:0] row, col;
  logic [7:0] red, green, blue;

  logic [3:0] btn_sync;
  Synchronizer #(4) btn_synchronizer (.clock(clk_40MHz), .async_in(BTN), .sync_out(btn_sync));
  assign reset = btn_sync[0];


  tester test(.row, .col, .red, .green, .blue);
  


  // Instantiate your TPG
  TestPatternGenerator tpg(
    .row,
    .col,
    .red,
    .green,
    .blue
   );

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


// 7 Segment Display
// 7 Segment Display Interface
module BCDtoSevenSegment
(input logic [3:0] number,
output logic [6:0] segment);

always_comb
    case(number)
        4'd0: segment = 7'b0111111;
        4'd1: segment = 7'b0000110;
        4'd2: segment = 7'b1011011;
        4'd3: segment = 7'b1001111;
        4'd4: segment = 7'b1100110;
        4'd5: segment = 7'b1101101;
        4'd6: segment = 7'b1111101;
        4'd7: segment = 7'b0000111;
        4'd8: segment = 7'b1111111;
        4'd9: segment = 7'b1100111;
    endcase

endmodule : BCDtoSevenSegment
