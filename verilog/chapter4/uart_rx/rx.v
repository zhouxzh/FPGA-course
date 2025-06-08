`timescale 1ns / 1ps

module uart_rx (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire rx,            // Serial input
    output reg rx_ready,      // Data ready signal
    output reg [7:0] rx_data  // Received data
);

    // Parameters for UART configuration
    parameter CLK_FREQ = 50000000;  // 50MHz system clock
    parameter BAUD_RATE = 115200;   // Baud rate
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // State machine states
    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam DATA = 3'b010;
    localparam STOP = 3'b011;
    localparam CLEANUP = 3'b100;
    
    // Internal registers
    reg [2:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] rx_data_reg;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_data_reg <= 0;
            rx_ready <= 1'b0;
            rx_data <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    rx_ready <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    // Detect start bit (falling edge on rx)
                    if (rx == 1'b0) begin
                        state <= START;
                    end
                end
                
                START: begin
                    // Wait for middle of start bit
                    if (clk_count < (CLKS_PER_BIT - 1) / 2) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        // Check if start bit is still low
                        if (rx == 1'b0) begin
                            // Reset counter for data bits
                            clk_count <= 0;
                            state <= DATA;
                        end else begin
                            // False start, go back to idle
                            state <= IDLE;
                        end
                    end
                end
                
                DATA: begin
                    // Wait for middle of data bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        // Sample the data bit
                        rx_data_reg[bit_index] <= rx;
                        
                        // Check if we have received all bits
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    // Wait for middle of stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        // Check if stop bit is high
                        if (rx == 1'b1) begin
                            rx_ready <= 1'b1;
                            rx_data <= rx_data_reg;
                        end
                        
                        clk_count <= 0;
                        state <= CLEANUP;
                    end
                end
                
                CLEANUP: begin
                    // Wait one clock cycle to clear rx_ready
                    state <= IDLE;
                    rx_ready <= 1'b0;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
