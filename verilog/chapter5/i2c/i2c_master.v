`timescale 1ns / 1ps

module i2c_master #(
    parameter integer CLK_DIV = 16
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [6:0] slave_addr,
    input  wire [7:0] tx_data,
    output reg        busy,
    output reg        done,
    output reg        ack_error,
    output reg [7:0]  debug_byte,
    output reg [2:0]  debug_phase,
    inout  wire       scl,
    inout  wire       sda
);

    localparam [3:0] S_IDLE      = 4'd0;
    localparam [3:0] S_START     = 4'd1;
    localparam [3:0] S_SEND_ADDR = 4'd2;
    localparam [3:0] S_ADDR_ACK  = 4'd3;
    localparam [3:0] S_SEND_DATA = 4'd4;
    localparam [3:0] S_DATA_ACK  = 4'd5;
    localparam [3:0] S_STOP      = 4'd6;
    localparam [3:0] S_FINISH    = 4'd7;

    reg [3:0]  state;
    reg [1:0]  phase;
    reg [7:0]  shift_reg;
    reg [2:0]  bit_count;
    reg [15:0] clk_div_cnt;
    reg        scl_drive_low;
    reg        sda_drive_low;
    reg        start_latched;

    wire sda_in = sda;

    assign scl = scl_drive_low ? 1'b0 : 1'bz;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            phase         <= 2'd0;
            shift_reg     <= 8'h00;
            bit_count     <= 3'd0;
            clk_div_cnt   <= 16'd0;
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;
            start_latched <= 1'b0;
            busy          <= 1'b0;
            done          <= 1'b0;
            ack_error     <= 1'b0;
            debug_byte    <= 8'h00;
            debug_phase   <= 3'd0;
        end else begin
            done <= 1'b0;

            if (start)
                start_latched <= 1'b1;

            if (clk_div_cnt < CLK_DIV - 1) begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end else begin
                clk_div_cnt <= 16'd0;

                case (state)
                    S_IDLE: begin
                        busy          <= 1'b0;
                        ack_error     <= 1'b0;
                        scl_drive_low <= 1'b0;
                        sda_drive_low <= 1'b0;
                        phase         <= 2'd0;
                        debug_phase   <= 3'd0;
                        if (start_latched) begin
                            busy       <= 1'b1;
                            shift_reg  <= {slave_addr, 1'b0};
                            debug_byte <= {slave_addr, 1'b0};
                            bit_count  <= 3'd7;
                            start_latched <= 1'b0;
                            state      <= S_START;
                        end
                    end

                    S_START: begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd2;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd0;
                                debug_phase   <= 3'd1;
                                state         <= S_SEND_ADDR;
                            end
                        endcase
                    end

                    S_SEND_ADDR: begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= ~shift_reg[bit_count];
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                if (bit_count == 3'd0) begin
                                    phase       <= 2'd0;
                                    debug_phase <= 3'd2;
                                    state       <= S_ADDR_ACK;
                                end else begin
                                    bit_count <= bit_count - 1'b1;
                                    phase     <= 2'd0;
                                end
                            end
                        endcase
                    end

                    S_ADDR_ACK: begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                if (sda_in != 1'b0)
                                    ack_error <= 1'b1;
                                phase <= 2'd2;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                shift_reg     <= tx_data;
                                debug_byte    <= tx_data;
                                bit_count     <= 3'd7;
                                phase         <= 2'd0;
                                debug_phase   <= 3'd3;
                                state         <= S_SEND_DATA;
                            end
                        endcase
                    end

                    S_SEND_DATA: begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= ~shift_reg[bit_count];
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                if (bit_count == 3'd0) begin
                                    phase       <= 2'd0;
                                    debug_phase <= 3'd4;
                                    state       <= S_DATA_ACK;
                                end else begin
                                    bit_count <= bit_count - 1'b1;
                                    phase     <= 2'd0;
                                end
                            end
                        endcase
                    end

                    S_DATA_ACK: begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                if (sda_in != 1'b0)
                                    ack_error <= 1'b1;
                                phase <= 2'd2;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd0;
                                debug_phase   <= 3'd5;
                                state         <= S_STOP;
                            end
                        endcase
                    end

                    S_STOP: begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd2;
                            end
                            default: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd0;
                                state         <= S_FINISH;
                            end
                        endcase
                    end

                    S_FINISH: begin
                        busy        <= 1'b0;
                        done        <= 1'b1;
                        debug_phase <= 3'd0;
                        state       <= S_IDLE;
                    end

                    default: begin
                        state <= S_IDLE;
                    end
                endcase
            end
        end
    end

endmodule