module spi_slave_rx_only (
    input wire clk,         // 系统时钟
    input wire sclk,        // SPI时钟（由主机提供）
    input wire cs,          // 片选（低电平有效）同时作为复位信号
    input wire mosi,        // 主机输出从机输入
    output reg [15:0] rx_data, // 接收到的16位数据
    output reg rx_done      // 接收完成标志（高电平脉冲）
);

// 内部寄存器
reg [15:0] rx_shift_reg = 16'h0000;   // 16位接收移位寄存器
reg [4:0] bit_cnt = 5'd0;             // 位计数器（0-15）
reg sclk_prev = 1'b0;                 // 用于检测边沿的SCLK上一个周期值
reg cs_sync = 1'b1;                   // 同步后的片选信号
reg sclk_rise;

// 同步cs信号以避免亚稳态
always @(posedge clk) begin
    cs_sync <= cs;
    sclk_prev <= sclk;
    sclk_rise = sclk && !sclk_prev;
end

// SPI接收逻辑
always @(posedge clk) begin
    rx_done <= 1'b0; // 默认清除完成标志
    
    // 当cs高电平（片选无效）时复位系统
    if (cs_sync) begin
        rx_shift_reg <= 16'h0000;
        bit_cnt <= 5'd0;
    end
    else if (sclk_rise) begin
        // 在SCLK上升沿采样MOSI
        rx_shift_reg <= {rx_shift_reg[14:0], mosi};
        
        if (bit_cnt == 5'd15) begin
            // 已接收16位数据
            rx_data <= {rx_shift_reg[14:0], mosi}; // 保存完整数据
            rx_done <= 1'b1;                      // 置位完成标志
            bit_cnt <= 5'd0;                      // 复位计数器
        end
        else begin
            bit_cnt <= bit_cnt + 1;               // 增加位计数器
        end
    end
end

endmodule