`default_nettype none
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

    // wait until next row starts

    #1 $finish;
end

endmodule : VGA_test