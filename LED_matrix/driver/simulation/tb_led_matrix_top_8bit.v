`timescale 1ns / 1ps

module tb_led_matrix_top();
    reg clk;          // 系统时钟 (50MHz)
    reg rst;          // 异步复位 (低有效)
    wire [7:0] led_row;
    wire [7:0] led_col_r;
    wire [7:0] led_col_g;
    wire [7:0] led_col_b;
    reg sclk;         // SPI时钟
    reg mosi;         // SPI数据线
    reg cs;           // 片选
    
    // 实例化待测设计 - 注意模块名改为 led_matrix_top
    led_matrix_top dut (
        .clk(clk),
        .rst(rst),
        .led_row(led_row),
        .led_col_r(led_col_r),
        .led_col_g(led_col_g),
        .led_col_b(led_col_b),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs)
    );
    
    // 时钟生成 (50MHz)
    always #10 clk = ~clk;  // 20ns周期 = 50MHz
    
    // SPI发送任务
    task spi_send;
        input [31:0] data;
        integer i;
        begin
            cs = 0;            // 选中设备
            #100;              // 建立时间
            
            // 发送32位数据 (MSB first)
            for (i = 0; i < 32; i = i + 1) begin
                sclk = 0;
                mosi = data[31-i];  // 发送高位先
                #50;
                sclk = 1;
                #50;
            end
            
            cs = 1;            // 取消选中
            sclk = 0;
            #100;              // 完成时间
        end
    endtask
    
    // 监控存储器内容 - 直接访问顶层模块的存储阵列
    function [23:0] get_led_color;
        input [5:0] addr;
        begin
            get_led_color = {dut.red[addr], dut.green[addr], dut.blue[addr]};
        end
    endfunction
    
    // 循环变量声明
    integer i, row;
    integer on_count, total_count;
    
    // 主测试流程
    initial begin
        // 初始化信号
        clk = 0;
        rst = 0;    // 复位有效
        sclk = 0;
        mosi = 0;
        cs = 1;     // SPI未选中
        #100;
        
        // 测试1: 复位状态测试
        rst = 0;    // 保持复位
        #200;
        // 验证所有输出应为默认值（LED关闭）
        if (led_row !== 8'hFF || led_col_r !== 8'hFF || 
            led_col_g !== 8'hFF || led_col_b !== 8'hFF) begin
            $display("错误：复位状态输出不正确");
            $stop;
        end
        $display("测试1: 复位状态验证通过");
        
        // 释放复位
        rst = 1;
        #1000;
        
        // 测试2: SPI数据传输测试
        spi_send(32'h00FF0000);  // LED0: 红色全亮
        spi_send(32'h0100FF00);  // LED1: 绿色全亮
        spi_send(32'h020000FF);  // LED2: 蓝色全亮
        spi_send(32'h03FFFFFF);  // LED3: 白色全亮
        spi_send(32'h04080808);  // LED4: 低亮度灰色
        
        // 验证存储器内容
        if (get_led_color(0) !== 24'hFF0000) begin
            $display("错误：LED0数据错误，预期24'hFF0000，实际%h", get_led_color(0));
            $stop;
        end
        if (get_led_color(1) !== 24'h00FF00) begin
            $display("错误：LED1数据错误，预期24'h00FF00，实际%h", get_led_color(1));
            $stop;
        end
        if (get_led_color(3) !== 24'hFFFFFF) begin
            $display("错误：LED3数据错误，预期24'hFFFFFF，实际%h", get_led_color(3));
            $stop;
        end
        $display("测试2: SPI数据传输验证通过");
        
        // 测试3: LED驱动功能测试
        #10000;  // 等待驱动开始工作
        
        // 验证行扫描功能
        $display("开始观察行扫描序列...");
        for (row = 0; row < 8; row = row + 1) begin
            // 等待行切换
            wait (led_row === ~(1 << row));
            $display("时间%t: 行%d选中", $time, row);
            
            // 验证列输出
            if (row == 0) begin
                if (led_col_r[0] !== 1'b0 || 
                    led_col_g[1] !== 1'b0 || 
                    led_col_b[2] !== 1'b0 || 
                    (led_col_r[3] !== 1'b0 || 
                     led_col_g[3] !== 1'b0 || 
                     led_col_b[3] !== 1'b0)) begin
                    $display("错误：第0行列输出不正确");
                    $display("R列: %b, G列: %b, B列: %b", led_col_r, led_col_g, led_col_b);
                    $stop;
                end
            end
            #10000;  // 等待部分PWM周期
        end
        
        // 测试4: PWM亮度控制测试
        $display("观察PWM亮度控制...");
        // 等待LED4（低亮度）所在行 - 直接访问顶层信号
        wait (dut.driver_row_counter == 3'd4);  // LED4在第4行
        #1000;
        
        // 统计LED4的亮灭时间（应为约50%占空比）
        on_count = 0;
        total_count = 0;
        for (i = 0; i < 1000; i = i + 1) begin
            if (led_col_r[4] === 1'b0) on_count = on_count + 1;  // 低电平表示点亮
            total_count = total_count + 1;
            #100;
        end
        $display("LED4亮度统计: 点亮率%d%%", (on_count*100)/total_count);
        
        $display("所有测试通过!");
        $finish;
    end
    
    // 波形记录
    initial begin
        $dumpfile("tb_led_matrix_top.vcd");
        $dumpvars(0, tb_led_matrix_top);
        #500000 $finish;  // 设置最大仿真时间
    end
endmodule