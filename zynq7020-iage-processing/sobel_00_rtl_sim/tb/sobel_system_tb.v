`timescale 1ns / 1ps

`ifndef IMG_WIDTH
`define IMG_WIDTH 128
`endif

`ifndef IMG_HEIGHT
`define IMG_HEIGHT 72
`endif

`ifndef CLK_FREQ
`define CLK_FREQ 12000000
`endif

`ifndef BAUD_RATE
`define BAUD_RATE 1000000
`endif

`ifndef INPUT_RGB_HEX
`define INPUT_RGB_HEX "data/input_rgb.hex"
`endif

`ifndef OUTPUT_PGM
`define OUTPUT_PGM "build/sobel_out.pgm"
`endif

`ifndef VCD_FILE
`define VCD_FILE "build/sobel_system_tb.vcd"
`endif

module sobel_system_tb;

    parameter integer WIDTH       = `IMG_WIDTH;
    parameter integer HEIGHT      = `IMG_HEIGHT;
    parameter integer CLK_FREQ    = `CLK_FREQ;
    parameter integer BAUD_RATE   = `BAUD_RATE;
    parameter integer CLK_PERIOD  = 1000000000 / CLK_FREQ;
    parameter integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    parameter integer PIXELS      = WIDTH * HEIGHT;
    parameter integer RGB_BYTES   = PIXELS * 3;

    reg clk;
    reg rst_n;
    reg uart_rx_line;

    wire        video_valid;
    wire [7:0]  video_r;
    wire [7:0]  video_g;
    wire [7:0]  video_b;
    wire [15:0] video_x;
    wire [15:0] video_y;
    wire        video_frame_done;
    wire        frame_start;
    wire        frame_done;
    wire        frame_error;

    reg [7:0] input_rgb [0:RGB_BYTES-1];
    reg [7:0] output_img [0:PIXELS-1];

    integer i;
    integer px;
    integer py;
    integer bit_idx;
    integer video_count;
    integer frame_error_count;
    integer frame_start_count;
    integer frame_done_count;
    integer before_video_count;
    integer before_error_count;
    integer timeout_count;
    integer pgm_file;
    sobel_system #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx_line),
        .video_valid(video_valid),
        .video_r(video_r),
        .video_g(video_g),
        .video_b(video_b),
        .video_x(video_x),
        .video_y(video_y),
        .video_frame_done(video_frame_done),
        .frame_start(frame_start),
        .frame_done(frame_done),
        .frame_error(frame_error)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            video_count       <= 0;
            frame_error_count <= 0;
            frame_start_count <= 0;
            frame_done_count  <= 0;
        end else begin
            if (video_valid) begin
                video_count <= video_count + 1;
                if ((video_x < WIDTH) && (video_y < HEIGHT)) begin
                    output_img[(video_y * WIDTH) + video_x] <= video_r;
                end
            end

            if (frame_error) begin
                frame_error_count <= frame_error_count + 1;
            end

            if (frame_start) begin
                frame_start_count <= frame_start_count + 1;
            end

            if (frame_done) begin
                frame_done_count <= frame_done_count + 1;
            end
        end
    end

    task send_uart_byte;
        input [7:0] data;
        begin
            uart_rx_line = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                uart_rx_line = data[bit_idx];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            uart_rx_line = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task send_frame_header;
        input [15:0] width;
        input [15:0] height;
        input [7:0] format;
        begin
            send_uart_byte(8'h55);
            send_uart_byte(8'haa);
            send_uart_byte(width[7:0]);
            send_uart_byte(width[15:8]);
            send_uart_byte(height[7:0]);
            send_uart_byte(height[15:8]);
            send_uart_byte(format);
        end
    endtask

    task send_bad_header;
        begin
            send_uart_byte(8'h55);
            send_uart_byte(8'h00);
            repeat (40) @(posedge clk);
        end
    endtask

    task send_bad_format_frame;
        begin
            send_frame_header(16'd4, 16'd4, 8'h99);
            repeat (40) @(posedge clk);
        end
    endtask

    task send_row_header;
        input [15:0] row;
        begin
            send_uart_byte(8'h33);
            send_uart_byte(8'hcc);
            send_uart_byte(row[7:0]);
            send_uart_byte(row[15:8]);
        end
    endtask

    task send_bad_line_frame;
        integer j;
        begin
            send_frame_header(16'd4, 16'd4, 8'h18);
            send_row_header(16'd5);

            for (j = 0; j < 4 * 3; j = j + 1) begin
                send_uart_byte(j[7:0]);
            end

            repeat (100) @(posedge clk);
        end
    endtask

    task send_valid_rgb_frame;
        integer row;
        integer col;
        integer idx;
        begin
            send_frame_header(WIDTH[15:0], HEIGHT[15:0], 8'h18);

            for (row = 0; row < HEIGHT; row = row + 1) begin
                send_row_header(row[15:0]);

                for (col = 0; col < WIDTH; col = col + 1) begin
                    idx = ((row * WIDTH) + col) * 3;

                    send_uart_byte(input_rgb[idx]);
                    send_uart_byte(input_rgb[idx + 1]);
                    send_uart_byte(input_rgb[idx + 2]);
                end
            end
        end
    endtask

    task wait_for_video_done;
        begin
            timeout_count = 0;
            while ((video_frame_done !== 1'b1) && (timeout_count < 3000000)) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end

            if (timeout_count >= 3000000) begin
                $fatal(1, "Timeout waiting for video_frame_done");
            end

            repeat (8) @(posedge clk);
        end
    endtask

    task write_pgm;
        begin
            pgm_file = $fopen(`OUTPUT_PGM, "w");
            if (pgm_file == 0) begin
                $fatal(1, "Could not open %s", `OUTPUT_PGM);
            end

            $fdisplay(pgm_file, "P2");
            $fdisplay(pgm_file, "%0d %0d", WIDTH, HEIGHT);
            $fdisplay(pgm_file, "255");

            for (py = 0; py < HEIGHT; py = py + 1) begin
                for (px = 0; px < WIDTH; px = px + 1) begin
                    $fwrite(pgm_file, "%0d ", output_img[(py * WIDTH) + px]);
                end
                $fwrite(pgm_file, "\n");
            end

            $fclose(pgm_file);
        end
    endtask

    initial begin
        $dumpfile(`VCD_FILE);
        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, uart_rx_line);
        $dumpvars(0, video_valid);
        $dumpvars(0, video_r);
        $dumpvars(0, video_g);
        $dumpvars(0, video_b);
        $dumpvars(0, video_x);
        $dumpvars(0, video_y);
        $dumpvars(0, video_frame_done);
        $dumpvars(0, frame_start);
        $dumpvars(0, frame_done);
        $dumpvars(0, frame_error);
        $dumpvars(0, dut.rx_valid);
        $dumpvars(0, dut.rx_data);
        $dumpvars(0, dut.rgb_valid);
        $dumpvars(0, dut.rgb_x);
        $dumpvars(0, dut.rgb_y);
        $dumpvars(0, dut.gray_valid);
        $dumpvars(0, dut.gray_x);
        $dumpvars(0, dut.gray_y);
        $dumpvars(0, dut.edge_valid);
        $dumpvars(0, dut.edge_x);
        $dumpvars(0, dut.edge_y);
        $dumpvars(0, dut.u_image_frame_rx.state);
        $dumpvars(0, dut.u_image_frame_rx.row_pixel_count);
        $dumpvars(0, dut.u_image_frame_rx.line_index);
        $dumpvars(0, dut.u_sobel_core.flush_active);
    end

    initial begin
        $readmemh(`INPUT_RGB_HEX, input_rgb);

        for (i = 0; i < PIXELS; i = i + 1) begin
            output_img[i] = 8'd0;
        end

        uart_rx_line = 1'b1;
        rst_n = 1'b0;
        repeat (20) @(posedge clk);
        rst_n = 1'b1;
        repeat (20) @(posedge clk);

        before_video_count = video_count;
        before_error_count = frame_error_count;
        send_bad_header();
        repeat (20) @(posedge clk);
        if (frame_error_count <= before_error_count) begin
            $fatal(1, "Bad header did not raise frame_error");
        end
        if (video_count != before_video_count) begin
            $fatal(1, "Bad header produced video output");
        end

        before_video_count = video_count;
        before_error_count = frame_error_count;
        send_bad_format_frame();
        repeat (20) @(posedge clk);
        if (frame_error_count <= before_error_count) begin
            $fatal(1, "Bad format did not raise frame_error");
        end
        if (video_count != before_video_count) begin
            $fatal(1, "Bad format produced video output");
        end

        before_video_count = video_count;
        before_error_count = frame_error_count;
        send_bad_line_frame();
        repeat (20) @(posedge clk);
        if (frame_error_count <= before_error_count) begin
            $fatal(1, "Bad line did not raise frame_error");
        end
        if (video_count != before_video_count) begin
            $fatal(1, "Bad line produced video output");
        end

        before_video_count = video_count;
        send_valid_rgb_frame();
        wait_for_video_done();

        if (frame_done_count != 1) begin
            $fatal(1, "Expected one completed frame, got %0d", frame_done_count);
        end

        if ((video_count - before_video_count) != (WIDTH * HEIGHT)) begin
            $fatal(1, "Unexpected video output count: got %0d expected %0d",
                   video_count - before_video_count, WIDTH * HEIGHT);
        end

        write_pgm();

        $display("Sobel RGB888 simulation passed");
        $display("Output image: %s", `OUTPUT_PGM);
        $display("Waveform: %s", `VCD_FILE);
        $finish;
    end

endmodule
