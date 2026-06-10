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

localparam SCAN_IDLE = 2'd0;
localparam SCAN_RUN  = 2'd1;
localparam SCAN_WAIT = 2'd2;

reg [11:0] h_cnt;
reg [11:0] v_cnt;
reg hs_reg;
reg vs_reg;
reg de_reg;
reg hs_reg_d0;
reg vs_reg_d0;
reg de_reg_d0;
reg [13:0] edge_rd_addr;
reg [7:0] edge_pixel;

reg [1:0] scan_state;
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
wire scan_issue;
wire scan_last;

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
assign scan_issue = (scan_state == SCAN_RUN);
assign scan_last = (scan_x == 7'd127) && (scan_y == 7'd71);
assign edge_wr_addr = {edge_y[6:0], 7'b0} + {7'd0, edge_x[6:0]};

assign hs = hs_reg_d0;
assign vs = vs_reg_d0;
assign de = de_reg_d0;
assign rgb_r = (de_reg_d0 && sobel_done) ? edge_pixel : 8'h00;
assign rgb_g = (de_reg_d0 && sobel_done) ? edge_pixel : 8'h00;
assign rgb_b = (de_reg_d0 && sobel_done) ? edge_pixel : 8'h00;

assign bram_we = 4'b0000;
assign bram_din = 32'd0;
assign bram_addr = bram_addr_reg;

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
        edge_rd_addr <= 14'd0;
        edge_pixel <= 8'd0;
    end else begin
        hs_reg <= hsync_now;
        vs_reg <= vsync_now;
        de_reg <= video_active;
        hs_reg_d0 <= hs_reg;
        vs_reg_d0 <= vs_reg;
        de_reg_d0 <= de_reg;
        edge_rd_addr <= video_active ? disp_addr : 14'd0;
        edge_pixel <= edge_mem[edge_rd_addr];
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
    end else begin
        scan_frame_start <= 1'b0;

        bram_en <= scan_issue || scan_valid_d1 || scan_valid_d2;
        bram_addr_reg <= scan_issue ? {16'd0, scan_word_addr, 2'b00} : 32'd0;

        scan_valid_d1 <= scan_issue;
        scan_valid_d2 <= scan_valid_d1;
        scan_x_d1 <= scan_x;
        scan_y_d1 <= scan_y;
        scan_x_d2 <= scan_x_d1;
        scan_y_d2 <= scan_y_d1;

        case (scan_state)
            SCAN_IDLE: begin
                if (video_frame_start) begin
                    scan_state <= SCAN_RUN;
                    scan_x <= 7'd0;
                    scan_y <= 7'd0;
                    scan_frame_start <= 1'b1;
                end
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
    if (edge_valid) begin
        edge_mem[edge_wr_addr] <= edge_data;
    end
end

endmodule
