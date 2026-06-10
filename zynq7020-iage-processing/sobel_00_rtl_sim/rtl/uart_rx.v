`timescale 1ns / 1ps

module uart_rx #(
    parameter integer CLK_FREQ = 50000000,
    parameter integer BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg        rx_valid,
    output reg [7:0]  rx_data
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_START = 3'd1;
    localparam [2:0] ST_DATA  = 3'd2;
    localparam [2:0] ST_STOP  = 3'd3;
    localparam [2:0] ST_DONE  = 3'd4;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            clk_count <= 16'd0;
            bit_index <= 3'd0;
            shift_reg <= 8'd0;
            rx_valid  <= 1'b0;
            rx_data   <= 8'd0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;

                    if (rx == 1'b0) begin
                        state <= ST_START;
                    end
                end

                ST_START: begin
                    if (clk_count == HALF_BIT) begin
                        clk_count <= 16'd0;
                        if (rx == 1'b0) begin
                            state <= ST_DATA;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                ST_DATA: begin
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= 16'd0;
                        shift_reg[bit_index] <= rx;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                ST_STOP: begin
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= 16'd0;
                        state <= ST_DONE;
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                ST_DONE: begin
                    rx_data  <= shift_reg;
                    rx_valid <= 1'b1;
                    state    <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
