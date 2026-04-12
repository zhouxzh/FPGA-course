`timescale 1ns / 1ps

module i2c_tb;

    localparam CLK_PERIOD  = 20;
    localparam SLAVE_ADDR  = 7'h42;
    localparam WRITE_DATA  = 8'hA6;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg [6:0]  slave_addr;
    reg [7:0]  tx_data;
    wire       busy;
    wire       done;
    wire       ack_error;
    wire [7:0] debug_byte;
    wire [2:0] debug_phase;
    tri1       scl;
    tri1       sda;
    wire [7:0] slave_rx_data;
    wire       slave_rx_done;
    wire       addr_match;
    integer    error_count;
    reg        slave_rx_done_seen;

    i2c_master #(
        .CLK_DIV(16)
    ) u_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .slave_addr(slave_addr),
        .tx_data(tx_data),
        .busy(busy),
        .done(done),
        .ack_error(ack_error),
        .debug_byte(debug_byte),
        .debug_phase(debug_phase),
        .scl(scl),
        .sda(sda)
    );

    i2c_slave #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_slave (
        .rst_n(rst_n),
        .scl(scl),
        .sda(sda),
        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done),
        .addr_match(addr_match)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_n      = 1'b0;
        start      = 1'b0;
        slave_addr = 7'h00;
        tx_data    = 8'h00;
        error_count = 0;
        slave_rx_done_seen = 1'b0;

        #100;
        rst_n = 1'b1;
        #100;

        @(posedge clk);
        slave_addr <= SLAVE_ADDR;
        tx_data    <= WRITE_DATA;
        start      <= 1'b1;
        @(posedge clk);
        start      <= 1'b0;

        @(posedge done);

        if (ack_error) begin
            $error("I2C ACK error detected during transaction");
            error_count = error_count + 1;
        end

        if (!addr_match) begin
            $error("I2C slave address did not match expected value");
            error_count = error_count + 1;
        end

        if (slave_rx_data !== WRITE_DATA) begin
            $error("I2C slave receive failed: expect=%h, recv=%h", WRITE_DATA, slave_rx_data);
            error_count = error_count + 1;
        end

        if (!slave_rx_done_seen) begin
            $error("I2C slave should assert an rx_done pulse after one byte write");
            error_count = error_count + 1;
        end

        #200;
        if (error_count == 0)
            $display("I2C test passed: addr=%h data=%h", SLAVE_ADDR, slave_rx_data);
        else
            $display("I2C test failed with %0d error(s)", error_count);
        $finish;
    end

    initial begin
        $dumpfile("i2c_tb.vcd");
        $dumpvars(0, i2c_tb);
    end

    always @(posedge slave_rx_done or negedge rst_n) begin
        if (!rst_n)
            slave_rx_done_seen <= 1'b0;
        else
            slave_rx_done_seen <= 1'b1;
    end

endmodule