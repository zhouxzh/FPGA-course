module hdmi_bram_display(
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
localparam IMG_WIDTH = 128;
localparam IMG_HEIGHT = 72;
localparam SCALE_X = H_ACTIVE / IMG_WIDTH;
localparam SCALE_Y = V_ACTIVE / IMG_HEIGHT;

reg [11:0] h_cnt;
reg [11:0] v_cnt;
reg hs_reg;
reg vs_reg;
reg de_reg;
reg hs_reg_d0;
reg vs_reg_d0;
reg de_reg_d0;
reg hs_reg_d1;
reg vs_reg_d1;
reg de_reg_d1;
reg [31:0] bram_addr_reg;
reg [23:0] pixel_reg;

wire h_active;
wire v_active;
wire video_active;
wire hsync_now;
wire vsync_now;
wire [11:0] active_x;
wire [11:0] active_y;
wire [6:0] image_x;
wire [6:0] image_y;
wire [13:0] image_word_addr;

assign h_active = (h_cnt >= H_START[11:0]) && (h_cnt < (H_START + H_ACTIVE));
assign v_active = (v_cnt >= V_START[11:0]) && (v_cnt < (V_START + V_ACTIVE));
assign video_active = h_active && v_active;

assign hsync_now = (h_cnt >= H_FP[11:0]) && (h_cnt < (H_FP + H_SYNC));
assign vsync_now = (v_cnt >= V_FP[11:0]) && (v_cnt < (V_FP + V_SYNC));

assign active_x = h_cnt - H_START[11:0];
assign active_y = v_cnt - V_START[11:0];
assign image_x = active_x / SCALE_X;
assign image_y = active_y / SCALE_Y;
assign image_word_addr = {image_y, 7'b0} + {7'd0, image_x};

assign hs = hs_reg_d1;
assign vs = vs_reg_d1;
assign de = de_reg_d1;
assign rgb_r = de_reg_d1 ? pixel_reg[23:16] : 8'h00;
assign rgb_g = de_reg_d1 ? pixel_reg[15:8]  : 8'h00;
assign rgb_b = de_reg_d1 ? pixel_reg[7:0]   : 8'h00;

assign bram_we = 4'b0000;
assign bram_din = 32'd0;
assign bram_addr = bram_addr_reg;

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
        hs_reg_d1 <= 1'b0;
        vs_reg_d1 <= 1'b0;
        de_reg_d1 <= 1'b0;
        bram_en <= 1'b0;
        bram_addr_reg <= 32'd0;
        pixel_reg <= 24'd0;
    end else begin
        hs_reg <= hsync_now;
        vs_reg <= vsync_now;
        de_reg <= video_active;
        hs_reg_d0 <= hs_reg;
        vs_reg_d0 <= vs_reg;
        de_reg_d0 <= de_reg;
        hs_reg_d1 <= hs_reg_d0;
        vs_reg_d1 <= vs_reg_d0;
        de_reg_d1 <= de_reg_d0;
        bram_en <= video_active;
        bram_addr_reg <= video_active ? {16'd0, image_word_addr, 2'b00} : 32'd0;
        pixel_reg <= bram_dout[23:0];
    end
end

endmodule
