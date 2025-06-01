`timescale 1ns/1ps

module tb_spi_slave_rx_only();
    reg clk;
    reg sclk;
    reg cs;
    reg mosi;
    wire [15:0] rx_data;
    wire rx_done;
    
    // 实例化被测模块
    spi_slave_rx_only uut (
        .clk(clk),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    
    // 时钟生成
    always #5 clk = ~clk;  // 100MHz系统时钟
    
    // SPI时钟生成
    always #25 sclk = ~sclk;  // 20MHz SPI时钟
    
    // 测试向量生成
    initial begin
        // 初始化信号
        clk = 0;
        sclk = 0;
        cs = 1;  // 初始状态为复位（片选无效）
        mosi = 0;
        
        // 测试1：正常数据传输
        #100;
        cs = 0;  // 激活片选，开始传输
        // 发送数据 0xA55A (1010 0101 0101 1010)
        #10 mosi = 1; #50;  // bit15
        #10 mosi = 0; #50;  // bit14
        #10 mosi = 1; #50;  // bit13
        #10 mosi = 0; #50;  // bit12
        #10 mosi = 0; #50;  // bit11
        #10 mosi = 1; #50;  // bit10
        #10 mosi = 0; #50;  // bit9
        #10 mosi = 1; #50;  // bit8
        #10 mosi = 0; #50;  // bit7
        #10 mosi = 1; #50;  // bit6
        #10 mosi = 0; #50;  // bit5
        #10 mosi = 1; #50;  // bit4
        #10 mosi = 1; #50;  // bit3
        #10 mosi = 0; #50;  // bit2
        #10 mosi = 1; #50;  // bit1
        #10 mosi = 0; #50;  // bit0
        cs = 1;  // 取消片选，复位系统
        #100;
        
        // 测试2：传输中途复位
        #100;
        cs = 0;  // 激活片选，开始传输
        // 发送数据 0x1234 (0001 0010 0011 0100)
        #10 mosi = 0; #50;  // bit15
        #10 mosi = 0; #50;  // bit14
        #10 mosi = 0; #50;  // bit13
        #10 mosi = 1; #50;  // bit12
        #10 mosi = 0; #50;  // bit11
        #10 mosi = 0; #50;  // bit10
        #10 mosi = 1; #50;  // bit9
        #10 mosi = 0; #50;  // bit8
        // 中途复位
        cs = 1;  // 取消片选，复位系统
        #100;
        
        // 测试3：复位后继续传输
        #100;
        cs = 0;  // 重新激活片选
        // 重新发送完整数据 0x5678 (0101 0110 0111 1000)
        #10 mosi = 0; #50;  // bit15
        #10 mosi = 1; #50;  // bit14
        #10 mosi = 0; #50;  // bit13
        #10 mosi = 1; #50;  // bit12
        #10 mosi = 0; #50;  // bit11
        #10 mosi = 1; #50;  // bit10
        #10 mosi = 1; #50;  // bit9
        #10 mosi = 0; #50;  // bit8
        #10 mosi = 0; #50;  // bit7
        #10 mosi = 1; #50;  // bit6
        #10 mosi = 1; #50;  // bit5
        #10 mosi = 1; #50;  // bit4
        #10 mosi = 0; #50;  // bit3
        #10 mosi = 0; #50;  // bit2
        #10 mosi = 0; #50;  // bit1
        #10 mosi = 0; #50;  // bit0
        cs = 1;  // 取消片选，复位系统
        #200;
        
        $finish;
    end
    
    // 监控输出
    always @(posedge rx_done) begin
        $display("Time = %0t: Received data = 0x%h", $time, rx_data);
    end
    
    initial begin
        $dumpfile("spi_slave.vcd");
        $dumpvars(0, tb_spi_slave_rx_only);
    end
endmodule