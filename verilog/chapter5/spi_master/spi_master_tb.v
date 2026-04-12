`timescale 1ns / 1ps

module spi_master_tb;

    localparam CLK_PERIOD = 20;
    localparam MASTER_TX  = 8'hA5;
    localparam SLAVE_TX   = 8'h3C;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg [7:0]  tx_data;
    reg        miso;
    wire [7:0] rx_data;
    wire       busy;
    wire       done;
    wire       sclk;
    wire       mosi;
    wire       cs_n;

    reg [7:0] slave_shift;
    reg [7:0] master_observed;
    reg [2:0] sample_count;
    integer   error_count;

    spi_master #(
        .CLK_DIV(4)
    ) dut (
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

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    always @(negedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            slave_shift     <= SLAVE_TX;
            master_observed <= 8'h00;
            sample_count    <= 3'd7;
            miso            <= 1'b0;
        end else begin
            slave_shift     <= SLAVE_TX;
            master_observed <= 8'h00;
            sample_count    <= 3'd7;
            miso            <= SLAVE_TX[7];
        end
    end

    always @(posedge sclk) begin
        if (!cs_n) begin
            master_observed[sample_count] <= mosi;
            if (sample_count != 3'd0)
                sample_count <= sample_count - 1'b1;
        end
    end

    always @(negedge sclk) begin
        if (!cs_n) begin
            slave_shift <= {slave_shift[6:0], 1'b0};
            miso <= slave_shift[6];
        end
    end

    initial begin
        rst_n       = 1'b0;
        start       = 1'b0;
        tx_data     = 8'h00;
        miso        = 1'b0;
        error_count = 0;

        #100;
        rst_n = 1'b1;
        #40;

        if (cs_n !== 1'b1 || sclk !== 1'b0)
            $error("SPI master idle state should be cs_n=1 and sclk=0");

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

        if (master_observed !== MASTER_TX) begin
            $error("SPI master transmit failed: expect=%h, observed=%h", MASTER_TX, master_observed);
            error_count = error_count + 1;
        end

        if (cs_n !== 1'b1 || sclk !== 1'b0) begin
            $error("SPI master should return to idle after transfer");
            error_count = error_count + 1;
        end

        #100;
        if (error_count == 0)
            $display("SPI master test passed: tx=%h rx=%h", MASTER_TX, rx_data);
        else
            $display("SPI master test failed with %0d error(s)", error_count);
        $finish;
    end

    initial begin
        $dumpfile("spi_master_tb.vcd");
        $dumpvars(0, spi_master_tb);
    end

endmodule