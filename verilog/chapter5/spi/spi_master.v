`timescale 1ns / 1ps

module spi_master #(
    parameter integer CLK_DIV = 4
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,
    output reg        sclk,
    output reg        mosi,
    input  wire       miso,
    output reg        cs_n
);

    localparam [1:0] S_IDLE     = 2'd0;
    localparam [1:0] S_TRANSFER = 2'd1;
    localparam [1:0] S_FINISH   = 2'd2;

    reg [1:0]  state;
    reg [7:0]  tx_shift;
    reg [7:0]  rx_shift;
    reg [2:0]  bit_count;
    reg [15:0] clk_div_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            tx_shift    <= 8'h00;
            rx_shift    <= 8'h00;
            rx_data     <= 8'h00;
            bit_count   <= 3'd0;
            clk_div_cnt <= 16'd0;
            busy        <= 1'b0;
            done        <= 1'b0;
            sclk        <= 1'b0;
            mosi        <= 1'b0;
            cs_n        <= 1'b1;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy        <= 1'b0;
                    sclk        <= 1'b0;
                    cs_n        <= 1'b1;
                    clk_div_cnt <= 16'd0;

                    if (start) begin
                        busy      <= 1'b1;
                        cs_n      <= 1'b0;
                        tx_shift  <= tx_data;
                        rx_shift  <= 8'h00;
                        bit_count <= 3'd7;
                        mosi      <= tx_data[7];
                        state     <= S_TRANSFER;
                    end
                end

                S_TRANSFER: begin
                    if (clk_div_cnt < CLK_DIV - 1) begin
                        clk_div_cnt <= clk_div_cnt + 1'b1;
                    end else begin
                        clk_div_cnt <= 16'd0;
                        sclk <= ~sclk;

                        if (sclk == 1'b0) begin
                            rx_shift[bit_count] <= miso;

                            if (bit_count == 3'd0) begin
                                state <= S_FINISH;
                            end else begin
                                bit_count <= bit_count - 1'b1;
                            end
                        end else begin
                            mosi <= tx_shift[bit_count];
                        end
                    end
                end

                S_FINISH: begin
                    busy    <= 1'b0;
                    cs_n    <= 1'b1;
                    sclk    <= 1'b0;
                    rx_data <= rx_shift;
                    done    <= 1'b1;
                    state   <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule