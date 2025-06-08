`timescale 1ns / 1ps

module tb_led_driver();

// 测试参数
parameter CLK_PERIOD = 20;  // 50MHz时钟周期 (20ns)

// 模块输入输出
reg clk;
reg rst;
reg [7:0] red [0:63];
reg [7:0] green [0:63];
reg [7:0] blue [0:63];
wire [7:0] led_row;
wire [7:0] led_col_r;
wire [7:0] led_col_g;
wire [7:0] led_col_b;

// 实例化待测设计
led_driver uut (
    .clk(clk),
    .rst(rst),
    .red(red),
    .green(green),
    .blue(blue),
    .led_row(led_row),
    .led_col_r(led_col_r),
    .led_col_g(led_col_g),
    .led_col_b(led_col_b)
);

// 时钟生成
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// 测试控制
integer test_case;
integer i, j;
integer errors = 0;
integer frame_count = 0;
integer pwm_count = 0;
integer row_changes = 0;

// 初始化数组
initial begin
    // 初始化所有LED为关闭状态
    for (i = 0; i < 64; i = i + 1) begin
        red[i] = 8'h00;
        green[i] = 8'h00;
        blue[i] = 8'h00;
    end
    
    // 初始化测试环境
    rst = 1'b0;
    test_case = 0;
    
    // 复位设计
    #100;
    rst = 1'b1;
    #100;
    
    // 开始测试序列
    $display("Starting LED Driver Testbench");
    $display("============================");
    
    // 测试用例1: 全红测试
    test_case = 1;
    $display("[TEST CASE 1] All LEDs Red");
    for (i = 0; i < 64; i = i + 1) begin
        red[i] = 8'hFF;    // 最大亮度红色
        green[i] = 8'h00;
        blue[i] = 8'h00;
    end
    #(CLK_PERIOD * 256 * 8 * 2);  // 等待2帧
    
    // 测试用例2: 全绿测试
    test_case = 2;
    $display("[TEST CASE 2] All LEDs Green");
    for (i = 0; i < 64; i = i + 1) begin
        red[i] = 8'h00;
        green[i] = 8'hFF;  // 最大亮度绿色
        blue[i] = 8'h00;
    end
    #(CLK_PERIOD * 256 * 8 * 2);  // 等待2帧
    
    // 测试用例3: 全蓝测试
    test_case = 3;
    $display("[TEST CASE 3] All LEDs Blue");
    for (i = 0; i < 64; i = i + 1) begin
        red[i] = 8'h00;
        green[i] = 8'h00;
        blue[i] = 8'hFF;   // 最大亮度蓝色
    end
    #(CLK_PERIOD * 256 * 8 * 2);  // 等待2帧
    
    // 测试用例4: 对角线红色渐变
    test_case = 4;
    $display("[TEST CASE 4] Diagonal Red Gradient");
    for (i = 0; i < 8; i = i + 1) begin
        for (j = 0; j < 8; j = j + 1) begin
            if (i == j) begin
                red[i*8+j] = i * 32;  // 对角线渐变
                green[i*8+j] = 0;
                blue[i*8+j] = 0;
            end else begin
                red[i*8+j] = 0;
                green[i*8+j] = 0;
                blue[i*8+j] = 0;
            end
        end
    end
    #(CLK_PERIOD * 256 * 8 * 3);  // 等待3帧
    
    // 测试用例5: 棋盘格图案
    test_case = 5;
    $display("[TEST CASE 5] Checkerboard Pattern");
    for (i = 0; i < 8; i = i + 1) begin
        for (j = 0; j < 8; j = j + 1) begin
            if ((i+j) % 2 == 0) begin
                // 白色方格
                red[i*8+j] = 8'hFF;
                green[i*8+j] = 8'hFF;
                blue[i*8+j] = 8'hFF;
            end else begin
                // 黑色方格
                red[i*8+j] = 8'h00;
                green[i*8+j] = 8'h00;
                blue[i*8+j] = 8'h00;
            end
        end
    end
    #(CLK_PERIOD * 256 * 8 * 3);  // 等待3帧
    
    // 测试用例6: 动态变化测试
    test_case = 6;
    $display("[TEST CASE 6] Dynamic Pattern Change");
    for (integer k = 0; k < 5; k = k + 1) begin
        $display("  Pattern iteration %0d", k);
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                red[i*8+j] = (i*8+j) * 4;
                green[i*8+j] = (63 - (i*8+j)) * 4;
                blue[i*8+j] = (i*8+j) * 4;
            end
        end
        #(CLK_PERIOD * 256 * 8 * 1);  // 等待1帧
    end
    
    // 完成测试
    $display("\nTestbench completed");
    $display("Frames observed: %0d", frame_count);
    $display("PWM cycles observed: %0d", pwm_count);
    $display("Row changes observed: %0d", row_changes);
    
    if (errors) begin
        $display("TEST FAILED with %0d errors", errors);
    end else begin
        $display("TEST PASSED");
    end
    
    $finish;
end

// 监控行切换事件
always @(posedge clk) begin
    static reg [2:0] last_row_counter = 0;
    static reg [7:0] last_pwm_counter = 0;
    
    // 检测行计数器变化
    if (uut.row_counter !== last_row_counter) begin
        row_changes = row_changes + 1;
        last_row_counter = uut.row_counter;
    end
    
    // 检测PWM计数器回零（新帧开始）
    if (uut.pwm_counter == 0 && last_pwm_counter == 255) begin
        frame_count = frame_count + 1;
    end
    last_pwm_counter = uut.pwm_counter;
    
    // 计数器递增
    pwm_count = pwm_count + 1;
end

// PWM行为检查
always @(posedge clk) begin
    // 检查行选择信号
    if (led_row !== ~(8'b1 << uut.row_counter)) begin
        $display("ERROR at time %0t: Row select mismatch. Expected %b, got %b", 
                 $time, ~(8'b1 << uut.row_counter), led_row);
        errors = errors + 1;
    end
    
    // 检查列输出是否匹配当前行数据
    for (integer col = 0; col < 8; col = col + 1) begin
        integer led_index = uut.row_counter * 8 + col;
        reg [7:0] r_val = red[led_index];
        reg [7:0] g_val = green[led_index];
        reg [7:0] b_val = blue[led_index];
        
        // 检查红色通道
        if ((r_val > uut.pwm_counter) && led_col_r[col] !== 0) begin
            $display("ERROR at time %0t: R[%0d][%0d] should be ON (brightness %0d > PWM %0d)", 
                     $time, uut.row_counter, col, r_val, uut.pwm_counter);
            errors = errors + 1;
        end
        if ((r_val <= uut.pwm_counter) && led_col_r[col] !== 1) begin
            $display("ERROR at time %0t: R[%0d][%0d] should be OFF (brightness %0d <= PWM %0d)", 
                     $time, uut.row_counter, col, r_val, uut.pwm_counter);
            errors = errors + 1;
        end
        
        // 检查绿色通道
        if ((g_val > uut.pwm_counter) && led_col_g[col] !== 0) begin
            $display("ERROR at time %0t: G[%0d][%0d] should be ON (brightness %0d > PWM %0d)", 
                     $time, uut.row_counter, col, g_val, uut.pwm_counter);
            errors = errors + 1;
        end
        if ((g_val <= uut.pwm_counter) && led_col_g[col] !== 1) begin
            $display("ERROR at time %0t: G[%0d][%0d] should be OFF (brightness %0d <= PWM %0d)", 
                     $time, uut.row_counter, col, g_val, uut.pwm_counter);
            errors = errors + 1;
        end
        
        // 检查蓝色通道
        if ((b_val > uut.pwm_counter) && led_col_b[col] !== 0) begin
            $display("ERROR at time %0t: B[%0d][%0d] should be ON (brightness %0d > PWM %0d)", 
                     $time, uut.row_counter, col, b_val, uut.pwm_counter);
            errors = errors + 1;
        end
        if ((b_val <= uut.pwm_counter) && led_col_b[col] !== 1) begin
            $display("ERROR at time %0t: B[%0d][%0d] should be OFF (brightness %0d <= PWM %0d)", 
                     $time, uut.row_counter, col, b_val, uut.pwm_counter);
            errors = errors + 1;
        end
    end
end

// 波形记录
initial begin
    $dumpfile("led_driver_tb.vcd");
    $dumpvars(0, tb_led_driver);
    
    // 记录所有信号
    $dumpvars(1, uut);
end

endmodule