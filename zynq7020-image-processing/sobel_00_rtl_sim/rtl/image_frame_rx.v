`timescale 1ns / 1ps

module image_frame_rx #(
    parameter integer MAX_WIDTH  = 640,
    parameter integer MAX_HEIGHT = 480
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        byte_valid,
    input  wire [7:0]  byte_data,
    output reg         rgb_valid,
    output reg [7:0]   r,
    output reg [7:0]   g,
    output reg [7:0]   b,
    output reg [15:0]  x,
    output reg [15:0]  y,
    output reg         frame_start,
    output reg         frame_done,
    output reg         frame_error,
    output reg [15:0]  frame_width,
    output reg [15:0]  frame_height
);

    localparam [7:0] SOF0       = 8'h55;
    localparam [7:0] SOF1       = 8'haa;
    localparam [7:0] LINE0      = 8'h33;
    localparam [7:0] LINE1      = 8'hcc;
    localparam [7:0] FMT_RGB888 = 8'h18;

    localparam [3:0] ST_FIND_SYNC = 4'd0;
    localparam [3:0] ST_FRAME_1   = 4'd1;
    localparam [3:0] ST_W_LO      = 4'd2;
    localparam [3:0] ST_W_HI      = 4'd3;
    localparam [3:0] ST_H_LO      = 4'd4;
    localparam [3:0] ST_H_HI      = 4'd5;
    localparam [3:0] ST_FMT       = 4'd6;
    localparam [3:0] ST_LINE_1    = 4'd7;
    localparam [3:0] ST_LINE_Y_LO = 4'd8;
    localparam [3:0] ST_LINE_Y_HI = 4'd9;
    localparam [3:0] ST_R         = 4'd10;
    localparam [3:0] ST_G         = 4'd11;
    localparam [3:0] ST_B         = 4'd12;

    reg [3:0]  state;
    reg [15:0] next_width;
    reg [15:0] next_height;
    reg [15:0] line_index;
    reg [15:0] row_pixel_count;
    reg [7:0]  r_buf;
    reg [7:0]  g_buf;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_FIND_SYNC;
            rgb_valid       <= 1'b0;
            r               <= 8'd0;
            g               <= 8'd0;
            b               <= 8'd0;
            x               <= 16'd0;
            y               <= 16'd0;
            frame_start     <= 1'b0;
            frame_done      <= 1'b0;
            frame_error     <= 1'b0;
            frame_width     <= 16'd0;
            frame_height    <= 16'd0;
            next_width      <= 16'd0;
            next_height     <= 16'd0;
            line_index      <= 16'd0;
            row_pixel_count <= 16'd0;
            r_buf           <= 8'd0;
            g_buf           <= 8'd0;
        end else begin
            rgb_valid   <= 1'b0;
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            frame_error <= 1'b0;

            if (byte_valid) begin
                case (state)
                    ST_FIND_SYNC: begin
                        if (byte_data == SOF0) begin
                            state <= ST_FRAME_1;
                        end else if (byte_data == LINE0 && frame_width != 16'd0) begin
                            state <= ST_LINE_1;
                        end
                    end

                    ST_FRAME_1: begin
                        if (byte_data == SOF1) begin
                            state <= ST_W_LO;
                        end else if (byte_data == SOF0) begin
                            state <= ST_FRAME_1;
                        end else begin
                            state <= ST_FIND_SYNC;
                            frame_error <= 1'b1;
                        end
                    end

                    ST_W_LO: begin
                        next_width[7:0] <= byte_data;
                        state <= ST_W_HI;
                    end

                    ST_W_HI: begin
                        next_width[15:8] <= byte_data;
                        state <= ST_H_LO;
                    end

                    ST_H_LO: begin
                        next_height[7:0] <= byte_data;
                        state <= ST_H_HI;
                    end

                    ST_H_HI: begin
                        next_height[15:8] <= byte_data;
                        state <= ST_FMT;
                    end

                    ST_FMT: begin
                        if ((byte_data == FMT_RGB888) &&
                            (next_width != 16'd0) &&
                            (next_height != 16'd0) &&
                            (next_width <= MAX_WIDTH) &&
                            (next_height <= MAX_HEIGHT)) begin
                            frame_width  <= next_width;
                            frame_height <= next_height;
                            frame_start  <= 1'b1;
                            state        <= ST_FIND_SYNC;
                        end else begin
                            state <= ST_FIND_SYNC;
                            frame_error <= 1'b1;
                        end
                    end

                    ST_LINE_1: begin
                        if (byte_data == LINE1) begin
                            state <= ST_LINE_Y_LO;
                        end else if (byte_data == SOF0) begin
                            state <= ST_FRAME_1;
                        end else begin
                            state <= ST_FIND_SYNC;
                            frame_error <= 1'b1;
                        end
                    end

                    ST_LINE_Y_LO: begin
                        line_index[7:0] <= byte_data;
                        state <= ST_LINE_Y_HI;
                    end

                    ST_LINE_Y_HI: begin
                        line_index[15:8] <= byte_data;

                        if ({byte_data, line_index[7:0]} < frame_height) begin
                            row_pixel_count <= 16'd0;
                            state <= ST_R;
                        end else begin
                            state <= ST_FIND_SYNC;
                            frame_error <= 1'b1;
                        end
                    end

                    ST_R: begin
                        r_buf <= byte_data;
                        state <= ST_G;
                    end

                    ST_G: begin
                        g_buf <= byte_data;
                        state <= ST_B;
                    end

                    ST_B: begin
                        r         <= r_buf;
                        g         <= g_buf;
                        b         <= byte_data;
                        x         <= row_pixel_count;
                        y         <= line_index;
                        rgb_valid <= 1'b1;

                        if (row_pixel_count == frame_width - 1) begin
                            state <= ST_FIND_SYNC;
                            if (line_index == frame_height - 1) begin
                                frame_done <= 1'b1;
                            end
                        end else begin
                            row_pixel_count <= row_pixel_count + 16'd1;
                            state <= ST_R;
                        end
                    end

                    default: begin
                        state <= ST_FIND_SYNC;
                    end
                endcase
            end
        end
    end

endmodule
