`timescale 1ns / 1ps

module sobel_system #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 115200,
    parameter integer WIDTH     = 128,
    parameter integer HEIGHT    = 72
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx_i,
    output wire       video_valid,
    output wire [7:0] video_r,
    output wire [7:0] video_g,
    output wire [7:0] video_b,
    output wire [15:0] video_x,
    output wire [15:0] video_y,
    output wire       video_frame_done,
    output wire       frame_start,
    output wire       frame_done,
    output wire       frame_error
);

    wire       rx_valid;
    wire [7:0] rx_data;

    wire       rgb_valid;
    wire [7:0] rgb_r;
    wire [7:0] rgb_g;
    wire [7:0] rgb_b;
    wire [15:0] rgb_x;
    wire [15:0] rgb_y;
    wire [15:0] frame_width;
    wire [15:0] frame_height;

    wire       gray_valid;
    wire [7:0] gray_data;
    wire [15:0] gray_x;
    wire [15:0] gray_y;

    wire       edge_valid;
    wire [7:0] edge_data;
    wire [15:0] edge_x;
    wire [15:0] edge_y;
    wire       edge_frame_done;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx_i),
        .rx_valid(rx_valid),
        .rx_data(rx_data)
    );

    image_frame_rx #(
        .MAX_WIDTH(WIDTH),
        .MAX_HEIGHT(HEIGHT)
    ) u_image_frame_rx (
        .clk(clk),
        .rst_n(rst_n),
        .byte_valid(rx_valid),
        .byte_data(rx_data),
        .rgb_valid(rgb_valid),
        .r(rgb_r),
        .g(rgb_g),
        .b(rgb_b),
        .x(rgb_x),
        .y(rgb_y),
        .frame_start(frame_start),
        .frame_done(frame_done),
        .frame_error(frame_error),
        .frame_width(frame_width),
        .frame_height(frame_height)
    );

    rgb_to_gray u_rgb_to_gray (
        .clk(clk),
        .rst_n(rst_n),
        .rgb_valid(rgb_valid),
        .r(rgb_r),
        .g(rgb_g),
        .b(rgb_b),
        .x(rgb_x),
        .y(rgb_y),
        .gray_valid(gray_valid),
        .gray(gray_data),
        .gray_x(gray_x),
        .gray_y(gray_y)
    );

    sobel_core #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT)
    ) u_sobel_core (
        .clk(clk),
        .rst_n(rst_n),
        .frame_start(frame_start),
        .gray_valid(gray_valid),
        .gray(gray_data),
        .gray_x(gray_x),
        .gray_y(gray_y),
        .edge_valid(edge_valid),
        .edge_data(edge_data),
        .edge_x(edge_x),
        .edge_y(edge_y),
        .edge_frame_done(edge_frame_done)
    );

    video_stream_model u_video_stream_model (
        .clk(clk),
        .rst_n(rst_n),
        .edge_valid(edge_valid),
        .edge_data(edge_data),
        .edge_x(edge_x),
        .edge_y(edge_y),
        .edge_frame_done(edge_frame_done),
        .video_valid(video_valid),
        .video_r(video_r),
        .video_g(video_g),
        .video_b(video_b),
        .video_x(video_x),
        .video_y(video_y),
        .video_frame_done(video_frame_done)
    );

endmodule
