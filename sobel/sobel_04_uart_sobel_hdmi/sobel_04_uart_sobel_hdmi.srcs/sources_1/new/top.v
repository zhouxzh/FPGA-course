module top(
    inout [14:0] DDR_addr,
    inout [2:0] DDR_ba,
    inout DDR_cas_n,
    inout DDR_ck_n,
    inout DDR_ck_p,
    inout DDR_cke,
    inout DDR_cs_n,
    inout [3:0] DDR_dm,
    inout [31:0] DDR_dq,
    inout [3:0] DDR_dqs_n,
    inout [3:0] DDR_dqs_p,
    inout DDR_odt,
    inout DDR_ras_n,
    inout DDR_reset_n,
    inout DDR_we_n,
    inout FIXED_IO_ddr_vrn,
    inout FIXED_IO_ddr_vrp,
    inout [53:0] FIXED_IO_mio,
    inout FIXED_IO_ps_clk,
    inout FIXED_IO_ps_porb,
    inout FIXED_IO_ps_srstb,
    input sys_clk,
    output hdmi_oen,
    output TMDS_clk_n,
    output TMDS_clk_p,
    output [2:0] TMDS_data_n,
    output [2:0] TMDS_data_p
);

wire bram_clk;
wire bram_rst;
wire bram_en;
wire [3:0] bram_we;
wire [31:0] bram_addr;
wire [31:0] bram_din;
wire [31:0] bram_dout;

ps_uart_bram_hdmi_wrapper ps_uart_bram_hdmi_wrapper_i (
    .BRAM_PORTB_addr(bram_addr),
    .BRAM_PORTB_clk(bram_clk),
    .BRAM_PORTB_din(bram_din),
    .BRAM_PORTB_dout(bram_dout),
    .BRAM_PORTB_en(bram_en),
    .BRAM_PORTB_rst(bram_rst),
    .BRAM_PORTB_we(bram_we),
    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb)
);

hdmi_pl_top hdmi_pl_top_i (
    .sys_clk(sys_clk),
    .hdmi_oen(hdmi_oen),
    .TMDS_clk_n(TMDS_clk_n),
    .TMDS_clk_p(TMDS_clk_p),
    .TMDS_data_n(TMDS_data_n),
    .TMDS_data_p(TMDS_data_p),
    .bram_clk(bram_clk),
    .bram_rst(bram_rst),
    .bram_en(bram_en),
    .bram_we(bram_we),
    .bram_addr(bram_addr),
    .bram_din(bram_din),
    .bram_dout(bram_dout)
);

endmodule
