module tb_LED_SPI_Receiver();

// 测试信号
reg clk = 0;
reg rst = 1;
reg sclk = 0;
reg mosi = 0;
reg cs = 1; // 初始片选无效
wire [7:0] red [0:7][0:7];
wire [7:0] green [0:7][0:7];
wire [7:0] blue [0:7][0:7];
wire data_valid;
wire [5:0] last_addr;

// 实例化SPI接收器
LED_SPI_Receiver dut (
    .clk(clk),
    .rst(rst),
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs),
    .red(red),
    .green(green),
    .blue(blue),
    .data_valid(data_valid),
    .last_addr(last_addr)
);

// 50MHz系统时钟生成
always #10 clk = ~clk;

// SPI时钟生成 (5MHz)
always #100 sclk = ~sclk;

// 发送单个32位数据包的任务
task send_packet;
    input [5:0] address;
    input [23:0] rgb;
    reg [31:0] data;
    integer i;
begin
    data = {2'b00, address, rgb}; // 组合32位数据
    
    cs = 0; // 激活片选
    #200;   // 等待片选稳定
    
    // 发送32位数据 (MSB优先)
    for (i = 31; i >= 0; i = i - 1) begin
        mosi = data[i]; // 输出当前位
        #200;           // 等待SPI时钟周期
    end
    
    cs = 1; // 关闭片选
    #200;   // 完成传输
end
endtask

// 测试序列
initial begin
    // 初始化
    rst = 1;
    #100;
    rst = 0;
    #100;
    
    // 测试1: 发送地址0x00 (0,0) 红色LED
    send_packet(6'h00, {8'hFF, 8'h00, 8'h00});
    #500;
    
    // 验证数据
    if (red[0][0] !== 8'hFF || green[0][0] !== 8'h00 || blue[0][0] !== 8'h00) begin
        $display("Test 1 FAILED!");
        $finish;
    end
    
    // 测试2: 发送地址0x09 (1,1) 绿色LED
    send_packet(6'h09, {8'h00, 8'hFF, 8'h00});
    #500;
    
    // 验证数据
    if (red[1][1] !== 8'h00 || green[1][1] !== 8'hFF || blue[1][1] !== 8'h00) begin
        $display("Test 2 FAILED!");
        $finish;
    end
    
    // 测试3: 发送地址0x3F (7,7) 蓝色LED
    send_packet(6'h3F, {8'h00, 8'h00, 8'hFF});
    #500;
    
    // 验证数据
    if (red[7][7] !== 8'h00 || green[7][7] !== 8'h00 || blue[7][7] !== 8'hFF) begin
        $display("Test 3 FAILED!");
        $finish;
    end
    
    // 测试4: 发送无效地址 (8,8) - 应该被忽略
    send_packet(6'h38, {8'hFF, 8'hFF, 8'hFF}); // 行=7, 列=0 (有效)
    #200;
    send_packet(6'h40, {8'hFF, 8'h00, 8'h00}); // 无效地址(>63)
    #500;
    
    // 验证无效地址未更新数据
    if (red[7][0] !== 8'hFF) begin
        $display("Test 4 FAILED! Valid address not updated");
        $finish;
    end
    
    // 测试5: 部分传输中断
    cs = 0; // 激活片选
    #200;
    mosi = 1; // 发送1位
    #200;
    cs = 1; // 中断传输
    #500;
    
    // 验证未完成传输未更新数据
    if (data_valid !== 0) begin
        $display("Test 5 FAILED! Partial transmission should not set data_valid");
        $finish;
    end
    
    $display("All tests PASSED!");
    $finish;
end

endmodule