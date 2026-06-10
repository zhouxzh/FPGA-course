`timescale 1ns / 1ps

module video_stream_model (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        edge_valid,
    input  wire [7:0]  edge_data,
    input  wire [15:0] edge_x,
    input  wire [15:0] edge_y,
    input  wire        edge_frame_done,
    output reg         video_valid,
    output reg [7:0]   video_r,
    output reg [7:0]   video_g,
    output reg [7:0]   video_b,
    output reg [15:0]  video_x,
    output reg [15:0]  video_y,
    output reg         video_frame_done
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            video_valid      <= 1'b0;
            video_r          <= 8'd0;
            video_g          <= 8'd0;
            video_b          <= 8'd0;
            video_x          <= 16'd0;
            video_y          <= 16'd0;
            video_frame_done <= 1'b0;
        end else begin
            video_valid      <= edge_valid;
            video_frame_done <= edge_frame_done;

            if (edge_valid) begin
                video_r <= edge_data;
                video_g <= edge_data;
                video_b <= edge_data;
                video_x <= edge_x;
                video_y <= edge_y;
            end
        end
    end

endmodule
