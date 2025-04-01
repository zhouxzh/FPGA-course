`timescale 1ns/1ps  // 时间精度设置

module led_demo_tb;

  // 时钟参数
  parameter CLK_PERIOD = 20;  // 50MHz时钟周期

  // 测试信号声明
  reg   clk_tb;
  reg   rst_n_tb;
  wire  led_tb;

  // 波形记录（Icarus专用）
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, led_demo_tb);
  end

  // 时钟生成（持续运行）
  initial begin
    clk_tb = 1'b0;
    forever #(CLK_PERIOD/2) clk_tb = ~clk_tb;
  end

  // 复位控制序列
  initial begin
    rst_n_tb = 1'b0;
    #(CLK_PERIOD*3) rst_n_tb = 1'b1;  // 3个周期后释放复位
    #(CLK_PERIOD*100) $finish;         // 运行30个周期后结束
  end

  // DUT实例化
  led_demo dut_inst (
    .clk   (clk_tb),
    .rst_n (rst_n_tb),
    .led   (led_tb)
  );

endmodule
