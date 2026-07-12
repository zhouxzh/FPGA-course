`timescale 1ns / 1ps

module rgb_to_gray (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rgb_valid,
    input  wire [7:0] r,
    input  wire [7:0] g,
    input  wire [7:0] b,
    input  wire [15:0] x,
    input  wire [15:0] y,
    output reg        gray_valid,
    output reg [7:0]  gray,
    output reg [15:0] gray_x,
    output reg [15:0] gray_y
);

    wire [15:0] gray_calc;

    assign gray_calc = ({8'd0, r} * 16'd77) +
                       ({8'd0, g} * 16'd150) +
                       ({8'd0, b} * 16'd29);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_valid <= 1'b0;
            gray       <= 8'd0;
            gray_x     <= 16'd0;
            gray_y     <= 16'd0;
        end else begin
            gray_valid <= rgb_valid;
            gray_x     <= x;
            gray_y     <= y;
            gray       <= gray_calc[15:8];
        end
    end

endmodule
