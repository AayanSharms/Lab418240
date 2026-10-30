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
        8'b0: begin // Wall
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
    (input logic [9:0] row, col,
    output logic [7:0] red, green, blue);

    logic redOn, greenOn, blueOn;

    ColorModule cm (.module_type('b0), .red(redOn), .green(greenOn), .blue(blueOn));
    assign red = 8'hCC ? (col<=10'd49 & col >= 10'd20 & row >= 10'd10 & row <= 10'd589) : '0;
    assign blue = blueOn ? (col<=10'd49 & col >= 10'd20 & row >= 10'd10 & row <= 10'd589) : '0;
    assign green = greenOn ? (col<=10'd49 & col >= 10'd20 & row >= 10'd10 & row <= 10'd589) : '0;

endmodule : Wall

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