`timescale 1ns / 1ps

module uart_tx_tb;

    // Parameters
    parameter CLK_PERIOD = 20;  // 50MHz clock (20ns period)
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = 1000000000 / BAUD_RATE;  // Bit period in ns
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_done;
    wire tx;
    
    // Instantiate the UART transmitter
    uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .tx(tx)
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
        tx_data = 8'h00;
        
        // Apply reset
        #100;
        rst_n = 1;
        #100;
        
        // Test case 1: Send character 'A' (0x41)
        tx_data = 8'h41;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Test case 2: Send character '1' (0x31)
        tx_data = 8'h31;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Test case 3: Send character '!' (0x21)
        tx_data = 8'h21;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // End simulation
        $display("Simulation completed successfully");
        $finish;
    end
    
    // Monitor UART transmission
    initial begin
        $monitor("Time: %t, TX: %b, TX_DONE: %b", $time, tx, tx_done);
    end
    
    // Generate VCD file for waveform viewing
    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

endmodule
