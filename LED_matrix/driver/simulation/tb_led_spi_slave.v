`timescale 1ns / 1ps

module tb_led_spi_slave();

// 测试信号
reg clk = 0;
reg rst = 1;
reg spi_clk = 0;
wire sclk;
reg mosi = 0;
reg cs = 1; // 初始片选无效
wire [7:0] red [0:63];   // 修改为一维数组
wire [7:0] green [0:63]; // 修改为一维数组
wire [7:0] blue [0:63];  // 修改为一维数组
wire data_valid;

// 实例化SPI接收器
led_spi_slave dut (
    .clk(clk),
    .rst(rst),
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs),
    .red(red),
    .green(green),
    .blue(blue),
    .data_valid(data_valid)
);

// 50MHz系统时钟生成
always #10 clk = ~clk;

// SPI时钟生成 (1MHz)
always #500 spi_clk = ~spi_clk;
assign sclk = !cs & spi_clk;

// 发送单个32位数据包的任务
task send_packet;
    input [5:0] address;
    input [23:0] rgb;
    reg [31:0] data;
    integer i;
begin
    data = {2'b00, address, rgb}; // 组合32位数据
    
    cs = 0; // 激活片选
    #50;   // 等待片选稳定
    
    // 发送32位数据 (MSB优先)
    for (i = 31; i >= 0; i = i - 1) begin
        mosi = data[i]; // 输出当前位
        #1000;           // 等待SPI时钟周期
    end
    
    cs = 1; // 关闭片选
    #10000;   // 完成传输
end
endtask

// 设置波形文件输出
initial begin
    $dumpfile("led_spi_slave.vcd");  // 指定波形文件名
    $dumpvars(0, tb_led_spi_slave);  // 转储所有层次的信号
    $dumpvars(1, dut);               // 详细转储顶层模块内部信号
end

// 测试序列
initial begin
    // 初始化
    #1000;
    rst = 0;
    #10000;
    rst = 1;
    #10000;
    
    // 测试1: 发送地址0x00 (索引0) 红色LED
    send_packet(6'h00, {8'hFF, 8'h00, 8'h00});
    #1000;
    
    // 验证数据 (使用一维索引)
    if (red[0] !== 8'hFF || green[0] !== 8'h00 || blue[0] !== 8'h00) begin
        $display("Test 1 FAILED! Got R:%h G:%h B:%h", red[0], green[0], blue[0]);
        $finish;
    end
    
    // 测试2: 发送地址0x09 (索引9) 绿色LED
    send_packet(6'h09, {8'h00, 8'hFF, 8'h00});
    #10000;
    
    // 验证数据 (使用一维索引)
    if (red[9] !== 8'h00 || green[9] !== 8'hFF || blue[9] !== 8'h00) begin
        $display("Test 2 FAILED! Got R:%h G:%h B:%h", red[9], green[9], blue[9]);
        $finish;
    end
    
    // 测试3: 发送地址0x3F (索引63) 蓝色LED
    send_packet(6'h3F, {8'h00, 8'h00, 8'hFF});
    #10000;
    
    // 验证数据 (使用一维索引)
    if (red[63] !== 8'h00 || green[63] !== 8'h00 || blue[63] !== 8'hFF) begin
        $display("Test 3 FAILED! Got R:%h G:%h B:%h", red[63], green[63], blue[63]);
        $finish;
    end
    
    // 测试4: 发送有效和无效地址
    send_packet(6'h38, {8'hFF, 8'hFF, 8'hFF}); // 有效地址(56)
    #10000;

    // 验证有效地址更新，无效地址不更新
    if (red[56] !== 8'hFF) begin
        $display("Test 4 FAILED! Valid address not updated");
        $finish;
    end

    // 测试5: 部分传输中断
    cs = 0; // 激活片选
    #10000;
    mosi = 1; // 发送1位
    #10000;
    cs = 1; // 中断传输
    #10000;
    
    // 验证未完成传输未更新数据
    if (data_valid !== 0) begin
        $display("Test 5 FAILED! Partial transmission set data_valid");
        $finish;
    end
    
    $display("All tests PASSED!");
    $finish;
end

endmodule