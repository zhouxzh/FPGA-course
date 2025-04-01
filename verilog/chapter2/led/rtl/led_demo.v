// LED控制模块（十进制计数器触发）
module led_demo(
  input   wire    clk,    // 系统时钟（50MHz）
  input   wire    rst_n,  // 低电平复位信号
  output  reg     led     // LED输出
);

  reg [3:0] cnt;  // 4位计数器（计数范围0-10）

  // 时钟驱动计数器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 4'd0;
    end else begin
      cnt <= (cnt >= 4'd10) ? 4'd0 : cnt + 4'd1;
    end
  end

  // LED状态切换逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      led <= 1'b0;
    end else if (cnt == 4'd10) begin
      led <= ~led;
    end
  end

endmodule
