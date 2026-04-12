`timescale 1ns / 1ps

module spi_slave #(
    parameter [7:0] RESPONSE_DATA = 8'h3C
)(
    input  wire      rst_n,
    input  wire      sclk,
    input  wire      cs_n,
    input  wire      mosi,
    output reg       miso,
    output reg [7:0] rx_data,
    output reg       rx_done
);

    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    reg [2:0] bit_count;

    always @(negedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift  <= RESPONSE_DATA;
            rx_shift  <= 8'h00;
            rx_data   <= 8'h00;
            bit_count <= 3'd7;
            miso      <= 1'b0;
            rx_done   <= 1'b0;
        end else begin
            tx_shift  <= RESPONSE_DATA;
            rx_shift  <= 8'h00;
            bit_count <= 3'd7;
            miso      <= RESPONSE_DATA[7];
            rx_done   <= 1'b0;
        end
    end

    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift  <= 8'h00;
            rx_data   <= 8'h00;
            bit_count <= 3'd7;
            rx_done   <= 1'b0;
        end else if (!cs_n) begin
            rx_shift[bit_count] <= mosi;

            if (bit_count == 3'd0) begin
                rx_data   <= {rx_shift[7:1], mosi};
                bit_count <= 3'd7;
                rx_done   <= 1'b1;
            end else begin
                bit_count <= bit_count - 1'b1;
                rx_done   <= 1'b0;
            end
        end else begin
            rx_done <= 1'b0;
        end
    end

    always @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= RESPONSE_DATA;
            miso     <= 1'b0;
        end else if (!cs_n) begin
            tx_shift <= {tx_shift[6:0], 1'b0};
            miso     <= tx_shift[6];
        end else begin
            miso <= 1'b0;
        end
    end

endmodule