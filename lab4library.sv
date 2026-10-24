`default_nettype none

module Decoder
    #(parameter WIDTH = 8, IW = $clog2(WIDTH))
(
    output logic [WIDTH-1:0] D,
    input logic [IW-1:0] I,
    input logic en
);

    always_comb begin
        if (en == 0)
            D = '0;
        else begin
            D = '0;
            D[I] = 1'b1;
        end
    end
    
endmodule : Decoder

module BarrelShifter(
    output logic [15:0] S,
    input logic [15:0] V,
    input logic [3:0] by
);

    assign S = V << by;

endmodule : BarrelShifter

module Multiplexer
    # (parameter WIDTH = 8, SW = $clog2(WIDTH))
(
    output logic Y,
    input logic [WIDTH-1:0] I,
    input logic [SW-1:0] S
);
    assign Y = I[S];

endmodule: Multiplexer


module Mux2to1
    #(parameter WIDTH = 8)
(
    output logic [WIDTH-1:0] Y,
    input logic [WIDTH-1:0] I0, I1,
    input logic S
);

    assign Y = (S) ? I1:I0;

endmodule: Mux2to1

module MagComp
    #(parameter WIDTH = 8)
(  
    input logic [WIDTH-1:0] A, B,
    output logic AltB, AeqB, AgtB
);
    assign AeqB = (A==B);
    assign AltB = (A < B);
    assign AgtB = (A > B);

endmodule : MagComp

module Comparator
    #(parameter WIDTH = 4)
    (input logic [WIDTH-1:0] A, B,
    output logic AeqB);

    assign AeqB = (A == B);

endmodule : Comparator

module Adder
    # (parameter WIDTH = 5)
    (input  logic [WIDTH-1:0] A, B,
    input  logic       cin,
    output logic [WIDTH-1:0] sum,
    output logic       cout);

    assign {cout, sum} = A + B + cin;

endmodule : Adder
    
module Subtracter
    # (parameter WIDTH = 5)
    (input  logic [WIDTH-1:0] A, B,
    input  logic       bin,
    output logic [WIDTH-1:0] diff,
    output logic       bout);

    assign {bout, diff} = A - B - bin;

endmodule : Subtracter

module DFlipFlop
    (input logic D,
    input logic clock, reset_L, preset_L,
    output logic Q);

    always_ff @(posedge clock, negedge reset_L, negedge preset_L)
    if (~reset_L)
        Q <= 1'b0;
    else if (~preset_L)
        Q <= 1'b1;
    else
        Q <= D;

endmodule: DFlipFlop

module Register
    #(parameter WIDTH = 6)
    (input logic [WIDTH-1:0] D,
    input logic en, clear,
    input logic clock,
    output logic [WIDTH-1:0] Q);
    always_ff @(posedge clock)
        if (en)
            Q <= D;
        else if (clear)
            Q <= '0; 
endmodule: Register

module Counter
    #(parameter WIDTH = 4)
    (input logic clock,
    input logic clear,
    input logic en,
    input logic up,
    input logic load,
    output logic [WIDTH-1:0] Q,
    input logic [WIDTH-1:0] D);
    always_ff @(posedge clock)
        if (clear)
            Q <= 0;
        else if (load)
            Q <= D;
        else if (en)   
            if (up)
                Q <= Q + 1;
            else if (~up)
                Q <= Q - 1;
endmodule: Counter

module ShiftRegisterSIPO
    # (parameter WIDTH = 8)
    (input logic en, left, serial, clock,
    output logic [WIDTH-1:0] Q);

    always_ff @(posedge clock)
        if (en) begin  
            if (left)
                Q <= {Q[WIDTH-2:0], serial};
            else if (~left)
                Q <= {serial, Q[WIDTH-1:1]};
        end


endmodule: ShiftRegisterSIPO


// rangeCheck - two magComps connected to nor
module RangeCheck
    # (parameter WIDTH = 8)
    (input logic [WIDTH-1 : 0] high, low, val,
    output logic is_between);

    logic val_gt_high, val_lt_low;

    assign val_gt_high = (val > high);
    assign val_lt_low = (val < low);
    assign is_between = ~(val_gt_high | val_lt_low);

endmodule : RangeCheck

// offset check, uses adder and rangecheck to 

module OffsetCheck
    # (parameter WIDTH = 8)
    (input logic [WIDTH-1 : 0] delta, low, val,
    output logic is_between);

    logic [WIDTH-1:0] high;
    logic             cout;

    Adder #(.WIDTH(WIDTH)) addHigh(.A(delta), .B(low), 
    .cin(1'b0), .sum(high), .cout);

    RangeCheck #(.WIDTH(WIDTH)) rc(.high(high), .low(low), .val(val), .is_between(is_between));

endmodule : OffsetCheck


