`timescale 1ns / 1ps

module uart_tb;

    // Parameters
    parameter CLK_PERIOD = 20;    // 50MHz clock (20ns period)
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = 1000000000 / BAUD_RATE;  // Bit period in ns
    
    // Testbench signals
    reg clk;
    reg rst_n;
    wire rx;
    wire rx_ready;
    wire [7:0] rx_data;
    
    // Test control signals
    reg [7:0] test_data;
    reg tx_start;
    wire tx_done;
    
    // Instantiate UART transmitter (to generate test signals)
    uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(test_data),
        .tx_done(tx_done),
        .tx(rx)  // Connect TX output to RX input
    );
    
    // Instantiate UART receiver
    uart_rx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        tx_start = 0;
        test_data = 8'h00;
        
        // Apply reset
        #100;
        rst_n = 1;
        #100;
        
        // Test case 1: Send character 'A' (0x41)
        test_data = 8'h41;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Verify received data
        if (rx_data !== 8'h41 || rx_ready !== 1'b1) 
            $error("Test 1 Failed: Received 0x%h, Expected 0x41", rx_data);
        
        // Test case 2: Send character 'Z' (0x5A)
        test_data = 8'h5A;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Verify received data
        if (rx_data !== 8'h5A || rx_ready !== 1'b1) 
            $error("Test 2 Failed: Received 0x%h, Expected 0x5A", rx_data);
        
        // Test case 3: Send random data
        test_data = 8'hA5;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Verify received data
        if (rx_data !== 8'hA5 || rx_ready !== 1'b1) 
            $error("Test 3 Failed: Received 0x%h, Expected 0xA5", rx_data);
        
        // End simulation
        $display("All tests completed successfully");
        $finish;
    end
    
    // Monitor signals
    initial begin
        $monitor("Time: %t, RX: %b, Data: 0x%h, Ready: %b",
                $time, rx, rx_data, rx_ready);
    end
    
    // Generate VCD file for waveform viewing
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule
