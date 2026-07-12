module hdmi_bram_sobel_display(
    input clk,
    input rst,
    output hs,
    output vs,
    output de,
    output [7:0] rgb_r,
    output [7:0] rgb_g,
    output [7:0] rgb_b,
    output reg bram_en,
    output [3:0] bram_we,
    output [31:0] bram_addr,
    output [31:0] bram_din,
    input [31:0] bram_dout
);

parameter H_ACTIVE = 16'd1280;
parameter H_FP     = 16'd110;
parameter H_SYNC   = 16'd40;
parameter H_BP     = 16'd220;
parameter V_ACTIVE = 16'd720;
parameter V_FP     = 16'd5;
parameter V_SYNC   = 16'd5;
parameter V_BP     = 16'd20;

localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;
localparam H_START = H_FP + H_SYNC + H_BP;
localparam V_START = V_FP + V_SYNC + V_BP;
localparam IMG_WIDTH  = 128;
localparam IMG_HEIGHT = 72;
localparam SCALE_X = H_ACTIVE / IMG_WIDTH;
localparam SCALE_Y = V_ACTIVE / IMG_HEIGHT;

localparam CTRL_MODE_ADDR      = 32'h0000_9000;
localparam CTRL_THRESHOLD_ADDR = 32'h0000_9004;
localparam CTRL_OVERLAY_ADDR   = 32'h0000_9008;

localparam MODE_ORIGINAL = 2'd0;
localparam MODE_GRAY     = 2'd1;
localparam MODE_EDGE     = 2'd2;
localparam MODE_OVERLAY  = 2'd3;

localparam SCAN_IDLE              = 4'd0;
localparam SCAN_CTRL_MODE_REQ     = 4'd1;
localparam SCAN_CTRL_MODE_WAIT1   = 4'd2;
localparam SCAN_CTRL_MODE_WAIT2   = 4'd3;
localparam SCAN_CTRL_THR_REQ      = 4'd4;
localparam SCAN_CTRL_THR_WAIT1    = 4'd5;
localparam SCAN_CTRL_THR_WAIT2    = 4'd6;
localparam SCAN_CTRL_OVL_REQ      = 4'd7;
localparam SCAN_CTRL_OVL_WAIT1    = 4'd8;
localparam SCAN_CTRL_OVL_WAIT2    = 4'd9;
localparam SCAN_RUN               = 4'd10;
localparam SCAN_WAIT              = 4'd11;

reg [11:0] h_cnt;
reg [11:0] v_cnt;
reg hs_reg;
reg vs_reg;
reg de_reg;
reg hs_reg_d0;
reg vs_reg_d0;
reg de_reg_d0;
reg [13:0] display_rd_addr;
reg [7:0] edge_pixel;
reg [23:0] rgb_pixel;

reg [3:0] scan_state;
reg [6:0] scan_x;
reg [6:0] scan_y;
reg [31:0] bram_addr_reg;
reg scan_valid_d1;
reg scan_valid_d2;
reg [6:0] scan_x_d1;
reg [6:0] scan_y_d1;
reg [6:0] scan_x_d2;
reg [6:0] scan_y_d2;
reg scan_frame_start;
reg sobel_done;

reg [1:0] display_mode;
reg [7:0] threshold;
reg overlay_enable;

(* ram_style = "block" *) reg [23:0] rgb_mem [0:9215];
(* ram_style = "block" *) reg [7:0] edge_mem [0:9215];

wire h_active;
wire v_active;
wire video_active;
wire hsync_now;
wire vsync_now;
wire video_frame_start;
wire [11:0] active_x;
wire [11:0] active_y;
wire [6:0] disp_x;
wire [6:0] disp_y;
wire [13:0] disp_addr;
wire [13:0] scan_word_addr;
wire [13:0] scan_store_addr;
wire scan_issue;
wire scan_last;
wire ctrl_read_active;

wire gray_valid;
wire [7:0] gray;
wire [15:0] gray_x;
wire [15:0] gray_y;
wire edge_valid;
wire [7:0] edge_data;
wire [15:0] edge_x;
wire [15:0] edge_y;
wire edge_frame_done;
wire [13:0] edge_wr_addr;

wire [15:0] display_gray_sum;
wire [7:0] display_gray;
wire edge_on;
wire overlay_active;
reg [7:0] out_r;
reg [7:0] out_g;
reg [7:0] out_b;

assign h_active = (h_cnt >= H_START[11:0]) && (h_cnt < (H_START + H_ACTIVE));
assign v_active = (v_cnt >= V_START[11:0]) && (v_cnt < (V_START + V_ACTIVE));
assign video_active = h_active && v_active;

assign hsync_now = (h_cnt >= H_FP[11:0]) && (h_cnt < (H_FP + H_SYNC));
assign vsync_now = (v_cnt >= V_FP[11:0]) && (v_cnt < (V_FP + V_SYNC));
assign video_frame_start = (h_cnt == 12'd0) && (v_cnt == 12'd0);

assign active_x = h_cnt - H_START[11:0];
assign active_y = v_cnt - V_START[11:0];
assign disp_x = active_x / SCALE_X;
assign disp_y = active_y / SCALE_Y;
assign disp_addr = {disp_y, 7'b0} + {7'd0, disp_x};

assign scan_word_addr = {scan_y, 7'b0} + {7'd0, scan_x};
assign scan_store_addr = {scan_y_d2, 7'b0} + {7'd0, scan_x_d2};
assign scan_issue = (scan_state == SCAN_RUN);
assign scan_last = (scan_x == 7'd127) && (scan_y == 7'd71);
assign ctrl_read_active = (scan_state >= SCAN_CTRL_MODE_REQ) && (scan_state <= SCAN_CTRL_OVL_WAIT2);
assign edge_wr_addr = {edge_y[6:0], 7'b0} + {7'd0, edge_x[6:0]};

assign hs = hs_reg_d0;
assign vs = vs_reg_d0;
assign de = de_reg_d0;
assign rgb_r = (de_reg_d0 && sobel_done) ? out_r : 8'h00;
assign rgb_g = (de_reg_d0 && sobel_done) ? out_g : 8'h00;
assign rgb_b = (de_reg_d0 && sobel_done) ? out_b : 8'h00;

assign bram_we = 4'b0000;
assign bram_din = 32'd0;
assign bram_addr = bram_addr_reg;

assign display_gray_sum = ({8'd0, rgb_pixel[23:16]} * 8'd77) +
                          ({8'd0, rgb_pixel[15:8]}  * 8'd150) +
                          ({8'd0, rgb_pixel[7:0]}   * 8'd29);
assign display_gray = display_gray_sum[15:8];
assign edge_on = (edge_pixel >= threshold);
assign overlay_active = overlay_enable || (display_mode == MODE_OVERLAY);

always @(*) begin
    out_r = rgb_pixel[23:16];
    out_g = rgb_pixel[15:8];
    out_b = rgb_pixel[7:0];

    case (display_mode)
        MODE_GRAY: begin
            out_r = display_gray;
            out_g = display_gray;
            out_b = display_gray;
        end

        MODE_EDGE: begin
            out_r = edge_on ? 8'hff : 8'h00;
            out_g = edge_on ? 8'hff : 8'h00;
            out_b = edge_on ? 8'hff : 8'h00;
        end

        default: begin
            out_r = rgb_pixel[23:16];
            out_g = rgb_pixel[15:8];
            out_b = rgb_pixel[7:0];
        end
    endcase

    if ((display_mode != MODE_EDGE) && overlay_active && edge_on) begin
        out_r = 8'hff;
        out_g = 8'h20;
        out_b = 8'h20;
    end
end

rgb_to_gray u_rgb_to_gray (
    .clk(clk),
    .rst_n(~rst),
    .rgb_valid(scan_valid_d2),
    .r(bram_dout[23:16]),
    .g(bram_dout[15:8]),
    .b(bram_dout[7:0]),
    .x({9'd0, scan_x_d2}),
    .y({9'd0, scan_y_d2}),
    .gray_valid(gray_valid),
    .gray(gray),
    .gray_x(gray_x),
    .gray_y(gray_y)
);

sobel_core #(
    .WIDTH(IMG_WIDTH),
    .HEIGHT(IMG_HEIGHT)
) u_sobel_core (
    .clk(clk),
    .rst_n(~rst),
    .frame_start(scan_frame_start),
    .gray_valid(gray_valid),
    .gray(gray),
    .gray_x(gray_x),
    .gray_y(gray_y),
    .edge_valid(edge_valid),
    .edge_data(edge_data),
    .edge_x(edge_x),
    .edge_y(edge_y),
    .edge_frame_done(edge_frame_done)
);

always @(posedge clk) begin
    if (rst) begin
        h_cnt <= 12'd0;
    end else if (h_cnt == H_TOTAL - 1) begin
        h_cnt <= 12'd0;
    end else begin
        h_cnt <= h_cnt + 12'd1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        v_cnt <= 12'd0;
    end else if (h_cnt == H_TOTAL - 1) begin
        if (v_cnt == V_TOTAL - 1) begin
            v_cnt <= 12'd0;
        end else begin
            v_cnt <= v_cnt + 12'd1;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        hs_reg <= 1'b0;
        vs_reg <= 1'b0;
        de_reg <= 1'b0;
        hs_reg_d0 <= 1'b0;
        vs_reg_d0 <= 1'b0;
        de_reg_d0 <= 1'b0;
        display_rd_addr <= 14'd0;
        edge_pixel <= 8'd0;
        rgb_pixel <= 24'd0;
    end else begin
        hs_reg <= hsync_now;
        vs_reg <= vsync_now;
        de_reg <= video_active;
        hs_reg_d0 <= hs_reg;
        vs_reg_d0 <= vs_reg;
        de_reg_d0 <= de_reg;
        display_rd_addr <= video_active ? disp_addr : 14'd0;
        edge_pixel <= edge_mem[display_rd_addr];
        rgb_pixel <= rgb_mem[display_rd_addr];
    end
end

always @(posedge clk) begin
    if (rst) begin
        scan_state <= SCAN_IDLE;
        scan_x <= 7'd0;
        scan_y <= 7'd0;
        bram_addr_reg <= 32'd0;
        bram_en <= 1'b0;
        scan_valid_d1 <= 1'b0;
        scan_valid_d2 <= 1'b0;
        scan_x_d1 <= 7'd0;
        scan_y_d1 <= 7'd0;
        scan_x_d2 <= 7'd0;
        scan_y_d2 <= 7'd0;
        scan_frame_start <= 1'b0;
        sobel_done <= 1'b0;
        display_mode <= MODE_EDGE;
        threshold <= 8'd80;
        overlay_enable <= 1'b0;
    end else begin
        scan_frame_start <= 1'b0;

        bram_en <= scan_issue || scan_valid_d1 || scan_valid_d2 || ctrl_read_active;
        if (scan_issue) begin
            bram_addr_reg <= {16'd0, scan_word_addr, 2'b00};
        end

        scan_valid_d1 <= scan_issue;
        scan_valid_d2 <= scan_valid_d1;
        scan_x_d1 <= scan_x;
        scan_y_d1 <= scan_y;
        scan_x_d2 <= scan_x_d1;
        scan_y_d2 <= scan_y_d1;

        case (scan_state)
            SCAN_IDLE: begin
                if (video_frame_start) begin
                    scan_state <= SCAN_CTRL_MODE_REQ;
                    scan_x <= 7'd0;
                    scan_y <= 7'd0;
                    sobel_done <= 1'b0;
                end
            end

            SCAN_CTRL_MODE_REQ: begin
                bram_addr_reg <= CTRL_MODE_ADDR;
                scan_state <= SCAN_CTRL_MODE_WAIT1;
            end

            SCAN_CTRL_MODE_WAIT1: begin
                scan_state <= SCAN_CTRL_MODE_WAIT2;
            end

            SCAN_CTRL_MODE_WAIT2: begin
                display_mode <= bram_dout[1:0];
                scan_state <= SCAN_CTRL_THR_REQ;
            end

            SCAN_CTRL_THR_REQ: begin
                bram_addr_reg <= CTRL_THRESHOLD_ADDR;
                scan_state <= SCAN_CTRL_THR_WAIT1;
            end

            SCAN_CTRL_THR_WAIT1: begin
                scan_state <= SCAN_CTRL_THR_WAIT2;
            end

            SCAN_CTRL_THR_WAIT2: begin
                threshold <= bram_dout[7:0];
                scan_state <= SCAN_CTRL_OVL_REQ;
            end

            SCAN_CTRL_OVL_REQ: begin
                bram_addr_reg <= CTRL_OVERLAY_ADDR;
                scan_state <= SCAN_CTRL_OVL_WAIT1;
            end

            SCAN_CTRL_OVL_WAIT1: begin
                scan_state <= SCAN_CTRL_OVL_WAIT2;
            end

            SCAN_CTRL_OVL_WAIT2: begin
                overlay_enable <= bram_dout[0];
                scan_state <= SCAN_RUN;
                scan_frame_start <= 1'b1;
            end

            SCAN_RUN: begin
                if (scan_last) begin
                    scan_state <= SCAN_WAIT;
                    scan_x <= 7'd0;
                    scan_y <= 7'd0;
                end else if (scan_x == 7'd127) begin
                    scan_x <= 7'd0;
                    scan_y <= scan_y + 7'd1;
                end else begin
                    scan_x <= scan_x + 7'd1;
                end
            end

            SCAN_WAIT: begin
                if (edge_frame_done) begin
                    scan_state <= SCAN_IDLE;
                    sobel_done <= 1'b1;
                end
            end

            default: begin
                scan_state <= SCAN_IDLE;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (scan_valid_d2) begin
        rgb_mem[scan_store_addr] <= bram_dout[23:0];
    end

    if (edge_valid) begin
        edge_mem[edge_wr_addr] <= edge_data;
    end
end

endmodule
