//`default_nettype none
module VGA
(input logic clock_40MHz, reset,
output logic HS, VS, blank,
output logic [9:0] row, col);

logic hsclk_clear, hs_disp, hs_sync, row_done;
logic vsclk_clear, vs_disp, vs_sync, vs_blank, all_done;
logic [10:0] hsclk_count;
logic [19:0] vsclk_count;

Counter #(11) hsclock_counter (.clear(hsclk_clear), .clock(clock_40MHz), 
                                .en(1'b1), .up(1'b1), .load(1'b0), 
                                .D(11'b0), .Q(hsclk_count));

RangeCheck #(11) hs_dip_check (.val(hsclk_count), .high(11'd1015),
                                .low(11'd216), .is_between(hs_disp));
Counter #(10) col_counter (.clear(hsclk_clear), .clock(clock_40MHz),  
                            .en(hs_disp), .up(1'b1), .load(1'b0),
                            .D(10'b0), .Q(col));

Comparator #(11) hs_finish_row (.A(hsclk_count), .B(11'd1055), 
                                .AeqB(row_done));

Counter #(20) vsclock_counter (.clear(vsclk_clear), .clock(clock_40MHz), 
                                .en(1'b1), .up(1'b1), .load(1'b0),
                                .D(20'b0), .Q(vsclk_count));

Counter #(10) row_counter (.clear(vs_blank), .en(row_done), .up(1'b1), 
                        .load(1'b0), .D(10'b0), 
                        .clock(clock_40MHz), .Q(row));

RangeCheck #(20) vs_dip_check (.val(vsclk_count), .high(20'd662_111),
                                .low(20'd28_512), .is_between(vs_disp));

Comparator #(20) vs_finish (.A(vsclk_count), .B(20'd663_167), .AeqB(all_done));

assign VS = ~vs_sync;
assign HS = ~hs_sync;

assign blank       = ~(hs_disp & vs_disp);
assign hsclk_clear = reset | row_done;
assign vsclk_clear = reset | all_done;
assign vs_blank    = ~vs_disp;

RangeCheck #(11) hs_sync_check (.val(hsclk_count), .low(11'd0),
                                .high(11'd127), .is_between(hs_sync));

RangeCheck #(20) vs_sync_check (.val(vsclk_count), .low(20'd0),
                                .high(20'd4_223), .is_between(vs_sync));

endmodule : VGA



module VGA_test;
logic clock_40MHz, reset, HS, VS, blank;
logic [9:0] row, col;

VGA vg (.clock_40MHz, .reset, .HS, .VS, .blank, .row, .col);

// clock management
initial begin
    clock_40MHz = 0;
    forever #5 clock_40MHz = ~clock_40MHz;
end

logic [19:0] counter;

initial begin
    reset <= 1;
    @ (posedge clock_40MHz);
    reset <= 0;
    @ (posedge clock_40MHz);

    // get counter up to v_disp
    for (counter = 20'b0; counter < 20'd28_512; counter++) begin
        @ (posedge clock_40MHz);
    end

    // get counter to h_disp
    for (counter = 20'b0; counter < 20'd216; counter++) begin
        @ (posedge clock_40MHz);
    end

    for (counter = 20'b0; counter < 20'd20; counter++) begin
            $display("(row, col): (%d, %d), clock counter: %d", row, col, vg.vsclk_count);
        @ (posedge clock_40MHz);
    end

    // fast forward to end of row
    for (counter = 20'b0; counter < 20'd770; counter++) begin
        @ (posedge clock_40MHz);
    end

    // end of (0, x)
    for (counter = 20'b0; counter < 20'd12; counter++) begin
            $display("(row, col): (%d, %d), clock counter: %d", row, col, vg.vsclk_count);
        @ (posedge clock_40MHz);
    end

    // next row start:
    for (counter = 20'b0; counter < 20'd770; counter++) begin
        @ (posedge clock_40MHz);
    end

    // spams a bunch of clocks
    for (counter = 20'b0; counter < 3 * 'd633600; counter++) begin
        @ (posedge clock_40MHz);
    end



    // wait until next row starts

    #1 $finish;
end

endmodule : VGA_test

// Generates an 8-stripe color test pattern on the top half of the screen
// and black on the bottom half, for checking VGA timing.
module TestPatternGenerator
    (input  logic [9:0] row, col,
    output logic [7:0] red, green, blue);

    logic redOn, greenOn, blueOn, bottomHalf;
    logic greenLeft, greenRight, blue1, blue3, blue5, blue7;

    RangeCheck #(10) redCheck (.val(col), .low(10'd400), .high(10'd799),
                                .is_between(redOn));

    OffsetCheck #(10) greenLeftCheck (.val(col), .low(10'd200), .delta(10'd199),
                                        .is_between(greenLeft));

    RangeCheck #(10) greenRightCheck (.val(col), .low(10'd600), .high(10'd799),
                                        .is_between(greenRight));

    RangeCheck #(10) blue1Check (.val(col), .low(10'd100), .high(10'd199),
                                .is_between(blue1));

    RangeCheck #(10) blue3Check (.val(col), .low(10'd300), .high(10'd399),
                                .is_between(blue3));

    RangeCheck #(10) blue5Check (.val(col), .low(10'd500), .high(10'd599),
                                .is_between(blue5));
                                
    RangeCheck #(10) blue7Check (.val(col), .low(10'd700), .high(10'd799),
                                .is_between(blue7));

    RangeCheck #(10) bottomCheck (.val(row), .low(10'd300), .high(10'd599),
                                    .is_between(bottomHalf));

    assign greenOn = greenLeft | greenRight;
    assign blueOn  = blue1 | blue3 | blue5 | blue7;

    assign red   = (redOn   & ~bottomHalf) ? 8'hFF : 8'h00;
    assign green = (greenOn & ~bottomHalf) ? 8'hFF : 8'h00;
    assign blue  = (blueOn  & ~bottomHalf) ? 8'hFF : 8'h00;

endmodule : TestPatternGenerator

