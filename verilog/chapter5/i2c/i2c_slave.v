`timescale 1ns / 1ps

module i2c_slave #(
    parameter [6:0] SLAVE_ADDR = 7'h42
)(
    input  wire      rst_n,
    input  wire      scl,
    inout  wire      sda,
    output reg [7:0] rx_data,
    output reg       rx_done,
    output reg       addr_match
);

    localparam [2:0] S_IDLE     = 3'd0;
    localparam [2:0] S_ADDR     = 3'd1;
    localparam [2:0] S_ADDR_ACK = 3'd2;
    localparam [2:0] S_DATA     = 3'd3;
    localparam [2:0] S_DATA_ACK = 3'd4;

    reg [2:0] state;
    reg [7:0] addr_shift;
    reg [7:0] data_shift;
    reg [2:0] bit_count;
    reg       sda_drive_low;

    wire sda_in = sda;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    always @(negedge sda or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            addr_shift <= 8'h00;
            data_shift <= 8'h00;
            bit_count  <= 3'd7;
            rx_data    <= 8'h00;
            rx_done    <= 1'b0;
            addr_match <= 1'b0;
        end else if (scl == 1'b1) begin
            state      <= S_ADDR;
            addr_shift <= 8'h00;
            data_shift <= 8'h00;
            bit_count  <= 3'd7;
            rx_done    <= 1'b0;
            addr_match <= 1'b0;
        end
    end

    always @(posedge sda or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            sda_drive_low <= 1'b0;
        end else if (scl == 1'b1) begin
            state         <= S_IDLE;
            sda_drive_low <= 1'b0;
        end
    end

    always @(posedge scl or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            addr_shift <= 8'h00;
            data_shift <= 8'h00;
            bit_count  <= 3'd7;
            rx_data    <= 8'h00;
            rx_done    <= 1'b0;
            addr_match <= 1'b0;
        end else begin
            case (state)
                S_ADDR: begin
                    addr_shift[bit_count] <= sda_in;
                    if (bit_count == 3'd0) begin
                        addr_match <= ({addr_shift[7:1], sda_in} == {SLAVE_ADDR, 1'b0});
                        bit_count  <= 3'd7;
                        state      <= S_ADDR_ACK;
                    end else begin
                        bit_count <= bit_count - 1'b1;
                    end
                end

                S_ADDR_ACK: begin
                    state   <= addr_match ? S_DATA : S_IDLE;
                    rx_done <= 1'b0;
                end

                S_DATA: begin
                    data_shift[bit_count] <= sda_in;
                    if (bit_count == 3'd0) begin
                        rx_data   <= {data_shift[7:1], sda_in};
                        rx_done   <= 1'b1;
                        bit_count <= 3'd7;
                        state     <= S_DATA_ACK;
                    end else begin
                        bit_count <= bit_count - 1'b1;
                        rx_done   <= 1'b0;
                    end
                end

                S_DATA_ACK: begin
                    state <= S_IDLE;
                end

                default: begin
                    rx_done <= 1'b0;
                end
            endcase
        end
    end

    always @(negedge scl or negedge rst_n) begin
        if (!rst_n) begin
            sda_drive_low <= 1'b0;
        end else begin
            case (state)
                S_ADDR_ACK: begin
                    sda_drive_low <= addr_match;
                end
                S_DATA_ACK: begin
                    sda_drive_low <= 1'b1;
                end
                default: begin
                    sda_drive_low <= 1'b0;
                end
            endcase
        end
    end

endmodule