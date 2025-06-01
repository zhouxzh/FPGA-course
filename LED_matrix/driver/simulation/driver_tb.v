`timescale 1ns / 1ps

module led_matrix_driver_spi_tb();

// 测试参数
parameter CLK_PERIOD = 20;   // 50MHz时钟周期(20ns)
parameter SPI_CLK_PERIOD = 80; // 12.5MHz SPI时钟

// 模块输入信号
reg clk;
reg rst_n;
reg spi_sclk;
reg spi_mosi;
reg spi_cs_n;

// 模块输出信号
wire [7:0] row_sel;
wire [7:0] red_out;
wire [7:0] green_out;
wire [7:0] blue_out;

// 实例化待测试模块
led_matrix_driver_spi uut (
    .clk(clk),
    .rst_n(rst_n),
    .spi_sclk(spi_sclk),
    .spi_mosi(spi_mosi),
    .spi_cs_n(spi_cs_n),
    .row_sel(row_sel),
    .red_out(red_out),
    .green_out(green_out),
    .blue_out(blue_out)
);

// 系统时钟生成
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// SPI时钟生成
initial begin
    spi_sclk = 0;
    forever #(SPI_CLK_PERIOD/2) spi_sclk = ~spi_sclk;
end

// 测试控制
initial begin
    // 初始化
    rst_n = 0;
    spi_cs_n = 1;
    spi_mosi = 0;
    
    // 复位
    #(CLK_PERIOD*5) rst_n = 1;
    
    // 测试1: 通过SPI发送全亮白色
    send_spi_data(8'hFF);
    #(CLK_PERIOD*3000);
    
    // 测试2: 通过SPI发送全暗
    send_spi_data(8'h00);
    #(CLK_PERIOD*3000);
    
    // 测试3: 渐变测试图案
    send_gradient_pattern();
    #(CLK_PERIOD*10000);
    
    // 测试4: 单行扫描测试
    send_row_scan_pattern();
    #(CLK_PERIOD*10000);
    
    // 测试5: 单列扫描测试
    send_column_scan_pattern();
    #(CLK_PERIOD*10000);
    
    // 结束仿真
    $display("Simulation completed.");
    $finish;
end

// 发送SPI数据任务
task send_spi_data;
    input [7:0] value;
    integer i, j, k;
    reg [7:0] spi_data [0:191];
    begin
        // 准备SPI数据
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                spi_data[i*24 + j*3]   = value; // R
                spi_data[i*24 + j*3+1] = value; // G
                spi_data[i*24 + j*3+2] = value; // B
            end
        end
        
        // 开始SPI传输
        spi_cs_n = 0;
        #(SPI_CLK_PERIOD);
        
        // 发送192字节数据
        for (i = 0; i < 192; i = i+1) begin
            for (j = 7; j >= 0; j = j-1) begin
                spi_mosi = spi_data[i][j];
                #(SPI_CLK_PERIOD);
            end
        end
        
        // 结束SPI传输
        spi_cs_n = 1;
        #(SPI_CLK_PERIOD*2);
        
        $display("Sent SPI data with value: %d", value);
    end
endtask

// 发送渐变测试图案
task send_gradient_pattern;
    integer i, j, idx;
    reg [7:0] spi_data [0:191];
    begin
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                idx = i*24 + j*3;
                // R: 水平渐变 (0-255)
                spi_data[idx]   = j * 32;
                // G: 垂直渐变 (0-255)
                spi_data[idx+1] = i * 32;
                // B: 对角线渐变 (0-255)
                spi_data[idx+2] = (i + j) * 16;
            end
        end
        
        // 发送SPI数据
        spi_cs_n = 0;
        #(SPI_CLK_PERIOD);
        
        for (i = 0; i < 192; i = i+1) begin
            for (j = 7; j >= 0; j = j-1) begin
                spi_mosi = spi_data[i][j];
                #(SPI_CLK_PERIOD);
            end
        end
        
        spi_cs_n = 1;
        #(SPI_CLK_PERIOD*2);
        
        $display("Sent gradient pattern via SPI");
    end
endtask

// 发送行扫描测试图案
task send_row_scan_pattern;
    integer i, j, idx;
    reg [7:0] spi_data [0:191];
    begin
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                idx = i*24 + j*3;
                // 第3行全亮，其他行半亮
                spi_data[idx]   = (i == 3) ? 8'hFF : 8'h80;
                spi_data[idx+1] = (i == 3) ? 8'hFF : 8'h80;
                spi_data[idx+2] = (i == 3) ? 8'hFF : 8'h80;
            end
        end
        
        // 发送SPI数据
        spi_cs_n = 0;
        #(SPI_CLK_PERIOD);
        
        for (i = 0; i < 192; i = i+1) begin
            for (j = 7; j >= 0; j = j-1) begin
                spi_mosi = spi_data[i][j];
                #(SPI_CLK_PERIOD);
            end
        end
        
        spi_cs_n = 1;
        #(SPI_CLK_PERIOD*2);
        
        $display("Sent row scan pattern via SPI");
    end
endtask

// 发送列扫描测试图案
task send_column_scan_pattern;
    integer i, j, idx;
    reg [7:0] spi_data [0:191];
    begin
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                idx = i*24 + j*3;
                // 第4列全亮，其他列半亮
                spi_data[idx]   = (j == 4) ? 8'hFF : 8'h80;
                spi_data[idx+1] = (j == 4) ? 8'hFF : 8'h80;
                spi_data[idx+2] = (j == 4) ? 8'hFF : 8'h80;
            end
        end
        
        // 发送SPI数据
        spi_cs_n = 0;
        #(SPI_CLK_PERIOD);
        
        for (i = 0; i < 192; i = i+1) begin
            for (j = 7; j >= 0; j = j-1) begin
                spi_mosi = spi_data[i][j];
                #(SPI_CLK_PERIOD);
            end
        end
        
        spi_cs_n = 1;
        #(SPI_CLK_PERIOD*2);
        
        $display("Sent column scan pattern via SPI");
    end
endtask

// 监控输出
always @(posedge clk) begin
    // 在PWM计数器为0时显示行切换信息
    if (uut.pwm_counter == 0) begin
        $display("Time: %0t ns | Switching to row: %0d", $time, uut.row_counter);
    end
    
    // 检测SPI更新
    if (uut.spi_capture_rising) begin
        $display("Time: %0t ns | SPI data captured and updated", $time);
    end
end

// 波形记录
initial begin
    $dumpfile("led_matrix_driver_spi_tb.vcd");
    $dumpvars(0, led_matrix_driver_spi_tb);
end

endmodule