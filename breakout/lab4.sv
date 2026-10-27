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
  logic clock_40MHz, clock_200MHz, locked;

  // Define your signals here

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
    .clock_40MHz,
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
    .red(),        // TODO: Connect your red channel
    .green(),      // TODO: Connect your green channel
    .blue(),       // TODO: Connect your blue channel
    .hsync(),      // TODO: Connect your HS
    .vsync(),      // TODO: Connect your VS
    .vde(),        // TODO: Connect your blank signal

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
