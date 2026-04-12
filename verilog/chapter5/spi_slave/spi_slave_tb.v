`timescale 1ns / 1ps

module spi_slave_tb;

    localparam HALF_BIT  = 40;
    localparam MASTER_TX = 8'h96;
    localparam SLAVE_TX  = 8'h3C;

    reg        rst_n;
    reg        sclk;
    reg        cs_n;
    reg        mosi;
    wire       miso;
    wire [7:0] rx_data;
    wire       rx_done;

    reg [7:0] master_rx;
    integer   index;
    integer   error_count;
    reg       rx_done_seen;

    spi_slave #(
        .RESPONSE_DATA(SLAVE_TX)
    ) dut (
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    task spi_transfer_byte;
        input  [7:0] tx_byte;
        output [7:0] rx_byte;
        integer i;
        begin
            rx_byte = 8'h00;
            cs_n = 1'b0;
            mosi = tx_byte[7];
            #HALF_BIT;

            for (i = 7; i >= 0; i = i - 1) begin
                mosi = tx_byte[i];
                #HALF_BIT;
                sclk = 1'b1;
                rx_byte[i] = miso;
                #HALF_BIT;
                sclk = 1'b0;
            end

            cs_n = 1'b1;
            #HALF_BIT;
        end
    endtask

    always @(posedge rx_done) begin
        rx_done_seen = 1'b1;
    end

    initial begin
        rst_n       = 1'b0;
        sclk        = 1'b0;
        cs_n        = 1'b1;
        mosi        = 1'b0;
        master_rx   = 8'h00;
        error_count = 0;
        rx_done_seen = 1'b0;

        #100;
        rst_n = 1'b1;
        #80;

        if (miso !== 1'b0)
            $error("SPI slave idle MISO should be low when cs_n is high");

        spi_transfer_byte(MASTER_TX, master_rx);

        if (master_rx !== SLAVE_TX) begin
            $error("SPI slave transmit failed: expect=%h, recv=%h", SLAVE_TX, master_rx);
            error_count = error_count + 1;
        end

        if (rx_data !== MASTER_TX) begin
            $error("SPI slave receive failed: expect=%h, recv=%h", MASTER_TX, rx_data);
            error_count = error_count + 1;
        end

        if (!rx_done_seen) begin
            $error("SPI slave should assert rx_done when one byte is received");
            error_count = error_count + 1;
        end

        #100;
        if (error_count == 0)
            $display("SPI slave test passed: rx=%h tx=%h", rx_data, master_rx);
        else
            $display("SPI slave test failed with %0d error(s)", error_count);
        $finish;
    end

    initial begin
        $dumpfile("spi_slave_tb.vcd");
        $dumpvars(0, spi_slave_tb);
    end

endmodule