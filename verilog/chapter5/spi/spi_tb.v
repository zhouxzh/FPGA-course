`timescale 1ns / 1ps

module spi_tb;

    localparam CLK_PERIOD = 20;
    localparam MASTER_TX  = 8'hA5;
    localparam SLAVE_TX   = 8'h3C;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg [7:0]  tx_data;
    wire [7:0] rx_data;
    wire       busy;
    wire       done;
    wire       sclk;
    wire       mosi;
    wire       miso;
    wire       cs_n;
    wire [7:0] slave_rx_data;
    wire       slave_rx_done;
    integer    error_count;

    spi_master #(
        .CLK_DIV(4)
    ) u_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .busy(busy),
        .done(done),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    spi_slave #(
        .RESPONSE_DATA(SLAVE_TX)
    ) u_slave (
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_n   = 1'b0;
        start   = 1'b0;
        tx_data = 8'h00;
        error_count = 0;

        #100;
        rst_n = 1'b1;
        #40;

        @(posedge clk);
        tx_data <= MASTER_TX;
        start   <= 1'b1;
        @(posedge clk);
        start   <= 1'b0;

        @(posedge done);

        if (rx_data !== SLAVE_TX) begin
            $error("SPI master receive failed: expect=%h, recv=%h", SLAVE_TX, rx_data);
            error_count = error_count + 1;
        end

        if (slave_rx_data !== MASTER_TX) begin
            $error("SPI slave receive failed: expect=%h, recv=%h", MASTER_TX, slave_rx_data);
            error_count = error_count + 1;
        end

        if (cs_n !== 1'b1) begin
            $error("SPI chip-select should return high after transfer");
            error_count = error_count + 1;
        end

        #100;
        if (error_count == 0)
            $display("SPI test passed: master_tx=%h slave_rx=%h slave_tx=%h master_rx=%h", MASTER_TX, slave_rx_data, SLAVE_TX, rx_data);
        else
            $display("SPI test failed with %0d error(s)", error_count);
        $finish;
    end

    initial begin
        $dumpfile("spi_tb.vcd");
        $dumpvars(0, spi_tb);
    end

endmodule