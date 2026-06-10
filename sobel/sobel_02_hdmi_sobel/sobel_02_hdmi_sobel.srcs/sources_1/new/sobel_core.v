`timescale 1ns / 1ps

module sobel_core #(
    parameter integer WIDTH  = 128,
    parameter integer HEIGHT = 72
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        frame_start,
    input  wire        gray_valid,
    input  wire [7:0]  gray,
    input  wire [15:0] gray_x,
    input  wire [15:0] gray_y,
    output reg         edge_valid,
    output reg [7:0]   edge_data,
    output reg [15:0]  edge_x,
    output reg [15:0]  edge_y,
    output reg         edge_frame_done
);

    reg [7:0] line0 [0:WIDTH-1];
    reg [7:0] line1 [0:WIDTH-1];

    reg [7:0] top0;
    reg [7:0] top1;
    reg [7:0] top2;
    reg [7:0] mid0;
    reg [7:0] mid1;
    reg [7:0] mid2;
    reg [7:0] bot0;
    reg [7:0] bot1;
    reg [7:0] bot2;
    reg [7:0] prev2_pixel;
    reg [7:0] prev1_pixel;

    reg signed [11:0] gx;
    reg signed [11:0] gy;
    reg [11:0] abs_gx;
    reg [11:0] abs_gy;
    reg [12:0] mag;
    reg [15:0] out_x;
    reg [15:0] out_y;
    reg        flush_active;
    reg        flush_bottom_row;
    reg [15:0] flush_x;
    reg [15:0] flush_y;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_valid      <= 1'b0;
            edge_data       <= 8'd0;
            edge_x          <= 16'd0;
            edge_y          <= 16'd0;
            edge_frame_done <= 1'b0;
            top0 <= 8'd0;
            top1 <= 8'd0;
            top2 <= 8'd0;
            mid0 <= 8'd0;
            mid1 <= 8'd0;
            mid2 <= 8'd0;
            bot0 <= 8'd0;
            bot1 <= 8'd0;
            bot2 <= 8'd0;
            prev2_pixel <= 8'd0;
            prev1_pixel <= 8'd0;
            gx <= 12'sd0;
            gy <= 12'sd0;
            abs_gx <= 12'd0;
            abs_gy <= 12'd0;
            mag <= 13'd0;
            out_x <= 16'd0;
            out_y <= 16'd0;
            flush_active <= 1'b0;
            flush_bottom_row <= 1'b0;
            flush_x <= 16'd0;
            flush_y <= 16'd0;

            for (i = 0; i < WIDTH; i = i + 1) begin
                line0[i] <= 8'd0;
                line1[i] <= 8'd0;
            end
        end else begin
            edge_valid      <= 1'b0;
            edge_frame_done <= 1'b0;

            if (frame_start) begin
                edge_valid <= 1'b0;
                for (i = 0; i < WIDTH; i = i + 1) begin
                    line0[i] <= 8'd0;
                    line1[i] <= 8'd0;
                end
                top0 <= 8'd0;
                top1 <= 8'd0;
                top2 <= 8'd0;
                mid0 <= 8'd0;
                mid1 <= 8'd0;
                mid2 <= 8'd0;
                bot0 <= 8'd0;
                bot1 <= 8'd0;
                bot2 <= 8'd0;
                flush_active <= 1'b0;
                flush_bottom_row <= 1'b0;
                flush_x <= 16'd0;
                flush_y <= 16'd0;
            end

            if (flush_active) begin
                edge_valid <= 1'b1;
                edge_data  <= 8'd0;
                edge_x     <= flush_x;
                edge_y     <= flush_y;

                if (!flush_bottom_row) begin
                    if (flush_y == HEIGHT - 2) begin
                        flush_bottom_row <= 1'b1;
                        flush_x <= 16'd0;
                        flush_y <= HEIGHT - 1;
                    end else begin
                        flush_y <= flush_y + 16'd1;
                    end
                end else begin
                    if (flush_x == WIDTH - 1) begin
                        flush_active <= 1'b0;
                        edge_frame_done <= 1'b1;
                    end else begin
                        flush_x <= flush_x + 16'd1;
                    end
                end
            end

            if (gray_valid) begin
                prev2_pixel = (gray_y >= 2) ? line0[gray_x] : 8'd0;
                prev1_pixel = (gray_y >= 1) ? line1[gray_x] : 8'd0;

                if (gray_x == 16'd0) begin
                    top0 = 8'd0;
                    top1 = 8'd0;
                    mid0 = 8'd0;
                    mid1 = 8'd0;
                    bot0 = 8'd0;
                    bot1 = 8'd0;
                end

                top2 = prev2_pixel;
                mid2 = prev1_pixel;
                bot2 = gray;

                out_x = (gray_x >= 1) ? (gray_x - 16'd1) : 16'd0;
                out_y = (gray_y >= 1) ? (gray_y - 16'd1) : 16'd0;

                if ((gray_x >= 2) && (gray_y >= 2)) begin
                    gx = -$signed({4'd0, top0}) + $signed({4'd0, top2})
                         -($signed({4'd0, mid0}) <<< 1) + ($signed({4'd0, mid2}) <<< 1)
                         -$signed({4'd0, bot0}) + $signed({4'd0, bot2});
                    gy = -$signed({4'd0, top0}) - ($signed({4'd0, top1}) <<< 1) - $signed({4'd0, top2})
                         + $signed({4'd0, bot0}) + ($signed({4'd0, bot1}) <<< 1) + $signed({4'd0, bot2});

                    abs_gx = gx[11] ? (~gx + 12'd1) : gx;
                    abs_gy = gy[11] ? (~gy + 12'd1) : gy;
                    mag = abs_gx + abs_gy;

                    edge_data  <= (mag > 13'd255) ? 8'hff : mag[7:0];
                    edge_x     <= out_x;
                    edge_y     <= out_y;
                    edge_valid <= 1'b1;
                end

                if ((gray_x >= 1) && (gray_y >= 1) &&
                    ((out_x == 16'd0) || (out_y == 16'd0) ||
                     (out_x == WIDTH - 1) || (out_y == HEIGHT - 1))) begin
                    edge_data  <= 8'd0;
                    edge_x     <= out_x;
                    edge_y     <= out_y;
                    edge_valid <= 1'b1;
                end

                if ((gray_x == WIDTH - 1) && (gray_y == HEIGHT - 1)) begin
                    flush_active <= 1'b1;
                    flush_bottom_row <= 1'b0;
                    flush_x <= WIDTH - 1;
                    flush_y <= 16'd0;
                end

                line0[gray_x] <= line1[gray_x];
                line1[gray_x] <= gray;

                top0 <= top1;
                top1 <= top2;
                mid0 <= mid1;
                mid1 <= mid2;
                bot0 <= bot1;
                bot1 <= bot2;
            end
        end
    end

endmodule
