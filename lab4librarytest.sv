`default_nettype none

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
        