`timescale 1ns / 1ps

module uart_rx_tb;

// Parameters
parameter CLK_PERIOD = 20;    // 50MHz clock (20ns period)
parameter BAUD_RATE = 115200;
parameter BIT_PERIOD = 1000000000 / BAUD_RATE;  // Bit period in ns

// DUT Signals
reg clk;
reg rst_n;
reg rx;
wire [7:0] rx_data;
wire rx_ready;

// Instantiate DUT
uart_rx #(
    .CLK_FREQ(50000000),  // 50MHz
    .BAUD_RATE(BAUD_RATE)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .rx_data(rx_data),
    .rx_ready(rx_ready)
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
    rx = 1;
    
    // Reset sequence
    #100;
    rst_n = 1;
    #100;
    
    // Test case 1: Send 0x55 (01010101)
    send_byte(8'h55);
    #(BIT_PERIOD*3);
    
    // Verify reception
    if(rx_data !== 8'h55 || rx_ready !== 1'b1)
        $error("Test 1 failed: Received 0x%h", rx_data);
        
    // Test case 2: Send 0xAA (10101010)  
    send_byte(8'hAA);
    #(BIT_PERIOD*3);
    
    if(rx_data !== 8'hAA || rx_ready !== 1'b1)
        $error("Test 2 failed: Received 0x%h", rx_data);
    
    // End simulation
    $display("All tests completed");
    $finish;
end

// UART byte transmission task
task send_byte;
    input [7:0] data;
    integer i;
    begin
        // Start bit
        rx = 0;
        #BIT_PERIOD;
        
        // Data bits (LSB first)
        for(i=0; i<8; i=i+1) begin
            rx = data[i];
            #BIT_PERIOD;
        end
        
        // Stop bit
        rx = 1;
        #BIT_PERIOD;
    end
endtask

// Monitor signals
initial begin
    $monitor("Time: %t, RX: %b, Data: 0x%h, Ready: %b",
            $time, rx, rx_data, rx_ready);
end

// Generate VCD file
initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_tb);
end

endmodule
