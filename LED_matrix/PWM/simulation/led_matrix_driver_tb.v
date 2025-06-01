`timescale 1ns / 1ps

module tb_led_matrix();

reg clk;
reg rst_n;
wire [7:0] row_sel;
wire [7:0] red_out;
wire [7:0] green_out;
wire [7:0] blue_out;

// 实例化顶层模块
led_matrix_top uut (
    .clk(clk),
    .rst_n(rst_n),
    .row_sel(row_sel),
    .red_out(red_out),
    .green_out(green_out),
    .blue_out(blue_out)
);

// 时钟生成 (50MHz)
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 20ns周期 = 50MHz
end

// 复位信号
initial begin
    rst_n = 0;
    #100 rst_n = 1;         // 100ns后释放复位
end

// 设置波形文件输出
initial begin
    $dumpfile("led_matrix_driver_tb.vcd");  // 指定波形文件名
    $dumpvars(0, tb_led_matrix);       // 转储所有层次的信号
    $dumpvars(1, uut);                 // 详细转储顶层模块内部信号
end

// 减少display使用 - 只显示关键事件
reg [31:0] last_time;
initial last_time = 0;

always @(posedge uut.driver.row_counter) begin
    if ($time - last_time > 1_000_000) begin  // 每1ms显示一次
        $display("Time=%tms | Current Row=%d | Global Brightness=%d", 
                 $time/1_000_000.0, uut.driver.row_counter, uut.global_brightness);
        last_time = $time;
    end
end

// 测试持续时间
initial begin
    #200_000;  // 模拟200ms（实际测试建议至少2秒）
    $display("Simulation completed successfully");
    $finish;
end

endmodule