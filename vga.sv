`default_nettype none
module VGA
(input logic clock_40MHz, reset,
output logic HS, VS, blank,
output logic [9:0] row, col);

logic hsclk_clear, hsclk_en, hs_disp, row_done;
logic vsclk_clear, vs_disp, all_done;
logic [10:0] hsclk_count;
logic [19:0] vsclk_count;

Counter #(11) hsclock_counter (.clear(hsclk_clear), .clock(clock_40MHz), 
                                .en(hsclk_en), .up(1'b1), .load(1'b0), 
                                .D(11'b0), .Q(hsclk_count));

RangeCheck #(11) hs_dip_check (.val(hsclk_count), .high(11'd1016),
                                .low(11'd216), .is_between(hs_disp));
Counter #(10) col_counter (.clear(hsclk_clear), .clock(clock_40MHz),  
                            .en(hs_disp), .up(1'b1), .load(1'b0),
                            .D(10'b0), .Q(col));

Comparator #(11) hs_finish_row (.A(hsclk_count), .B(11'd1056), 
                                .AeqB(row_done));

Counter #(20) vsclock_counter (.clear(vsclk_clear), .clock(clock_40MHz), 
                                .en(1'b1), .up(1'b1), .load(1'b0),
                                .D(20'b0), .Q(vsclk_count));

Counter #(10) row_counter (.clear(~vs_disp), .en(row_done), .up(1'b1), 
                        .load(1'b0), .D(10'b0), 
                        .clock(clock_40MHz), .Q(row));

RangeCheck #(20) vs_dip_check (.val(vsclk_count), .high(20'd662_112),
                                .low(20'd28_512), .is_between(vs_disp));

Comparator #(20) vs_finish (.A(vsclk_count), .B(20'd663_168), .AeqB(all_done));

assign VS = vs_disp;
assign HS = hs_disp;

fsm fs (.clock_40MHz, .reset, .row_done, .vs_disp, .all_done,
        .blank, .hsclk_en, .hsclk_clear, .vsclk_clear);

endmodule : VGA

module fsm
  (input  logic clock_40MHz, reset,
   input  logic row_done, vs_disp, all_done,
   output logic blank, hsclk_en, hsclk_clear, vsclk_clear);

    // State assignment
  enum logic [1:0] {Init = 2'b00, vs_await = 2'b01, hs = 2'b10} currentState, nextState;

  // State Transitions and updates ??XX?? values
  always_comb begin
    case (currentState)
      Init: begin  // State Init
        nextState = vs_await;
        hsclk_clear = 1;
        vsclk_clear = 1;
        blank = 1;
        hsclk_en = 0;
        end
      vs_await: begin  // State vs_await
            nextState = (vs_disp) ? hs : vs_await;
            blank = ~vs_disp;
            hsclk_en = vs_disp;
            hsclk_clear = 0;
            vsclk_clear = 0;
        end
        hs: begin // State hs
            nextState = (all_done) ? vs_await : hs;
            blank = ~vs_disp;
            hsclk_en = vs_disp;
            hsclk_clear = row_done;
            vsclk_clear = all_done;
        end
    endcase
  end

    // Select States
  always_ff @(posedge clock_40MHz, posedge reset)
    if (reset)
      currentState <= Init;
    else
      currentState <= nextState;

endmodule: fsm


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
    reset <= 0; // drive reset

    // get counter up to v_disp
    for (counter = 20'b0; counter < 20'd28_512; counter++) begin
        @ (posedge clock_40MHz);
    end

    // get counter to h_disp
    for (counter = 20'b0; counter < 20'd216; counter++) begin
        @ (posedge clock_40MHz);
    end

    for (counter = 20'b0; counter < 20'd20; counter++) begin
            $display("(row, col): (%d, %d), clock counter: %d, state: %s", row, col, vg.vsclk_count, vg.fs.currentState.name);
        @ (posedge clock_40MHz);
    end

    // fast forward to end of row
    for (counter = 20'b0; counter < 20'd770; counter++) begin
        @ (posedge clock_40MHz);
    end

    // end of (0, x)
    for (counter = 20'b0; counter < 20'd12; counter++) begin
            $display("(row, col): (%d, %d), clock counter: %d, state: %s", row, col, vg.vsclk_count, vg.fs.currentState.name);
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