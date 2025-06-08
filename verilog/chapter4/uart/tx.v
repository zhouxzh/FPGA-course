`timescale 1ns / 1ps

module uart_tx (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire tx_start,      // Start transmission signal
    input wire [7:0] tx_data, // Data to transmit
    output reg tx_done,       // Transmission complete signal
    output reg tx             // Serial output
);

    // Parameters for UART configuration
    parameter CLK_FREQ = 50000000;  // 50MHz system clock
    parameter BAUD_RATE = 115200;   // Baud rate
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    // Internal registers
    reg [1:0] state;
    reg [1:0] next_state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_data_reg;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_data_reg <= 0;
            tx <= 1'b1;  // Idle state is high
            tx_done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;  // Idle state is high
                    tx_done <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        state <= START;
                    end
                end
                
                START: begin
                    tx <= 1'b0;  // Start bit is low
                    
                    // Wait for one bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    tx <= tx_data_reg[bit_index];
                    
                    // Wait for one bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        // Check if we have sent all bits
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;  // Stop bit is high
                    
                    // Wait for one bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        tx_done <= 1'b1;
                        clk_count <= 0;
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
