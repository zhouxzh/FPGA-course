module hdmi_pl_top(
    input sys_clk,
    output hdmi_oen,
    output TMDS_clk_n,
    output TMDS_clk_p,
    output [2:0] TMDS_data_n,
    output [2:0] TMDS_data_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT CLK" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL, MEM_SIZE 65536, MEM_WIDTH 32, READ_WRITE_MODE READ" *)
    output bram_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT RST" *)
    output bram_rst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT EN" *)
    output bram_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT WE" *)
    output [3:0] bram_we,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT ADDR" *)
    output [31:0] bram_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT DIN" *)
    output [31:0] bram_din,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORT DOUT" *)
    input [31:0] bram_dout
);

wire video_clk;
wire video_clk_5x;
wire video_locked;
wire video_hs;
wire video_vs;
wire video_de;
wire [7:0] video_r;
wire [7:0] video_g;
wire [7:0] video_b;
wire video_rst;
reg [3:0] video_rst_shift = 4'b1111;

assign bram_clk = video_clk;
assign bram_rst = video_rst;

always @(posedge video_clk) begin
    if (!video_locked) begin
        video_rst_shift <= 4'b1111;
    end else begin
        video_rst_shift <= {video_rst_shift[2:0], 1'b0};
    end
end

assign video_rst = video_rst_shift[3];

hdmi_bram_sobel_display hdmi_bram_sobel_display_m0(
    .clk(video_clk),
    .rst(video_rst),
    .hs(video_hs),
    .vs(video_vs),
    .de(video_de),
    .rgb_r(video_r),
    .rgb_g(video_g),
    .rgb_b(video_b),
    .bram_en(bram_en),
    .bram_we(bram_we),
    .bram_addr(bram_addr),
    .bram_din(bram_din),
    .bram_dout(bram_dout)
);

video_clock video_clock_m0
(
    .clk_in1(sys_clk),
    .clk_out1(video_clk),
    .clk_out2(video_clk_5x),
    .reset(1'b0),
    .locked(video_locked)
);

rgb2dvi_0 rgb2dvi_m0 (
    .TMDS_Clk_p(TMDS_clk_p),
    .TMDS_Clk_n(TMDS_clk_n),
    .TMDS_Data_p(TMDS_data_p),
    .TMDS_Data_n(TMDS_data_n),
    .oen(hdmi_oen),
    .aRst_n(video_locked),
    .vid_pData({video_r, video_g, video_b}),
    .vid_pVDE(video_de),
    .vid_pHSync(video_hs),
    .vid_pVSync(video_vs),
    .PixelClk(video_clk),
    .SerialClk(video_clk_5x)
);

endmodule

