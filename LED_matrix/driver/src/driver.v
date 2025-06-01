module led_matrix_driver_spi (
    input clk,          // 系统时钟 (建议50MHz)
    input rst_n,        // 异步复位 (低有效)
    // SPI接口
    input spi_sclk,     // SPI时钟
    input spi_mosi,     // SPI主出从入
    input spi_cs_n,     // SPI片选 (低有效)
    // LED阵列输出信号
    output reg [7:0] row_sel,   // 行选择 (低有效)
    output reg [7:0] red_out,   // R列输出 (低有效)
    output reg [7:0] green_out, // G列输出 (低有效)
    output reg [7:0] blue_out   // B列输出 (低有效)
);

// 亮度数据寄存器
reg [7:0] brightness_r [0:7][0:7]; // R亮度 [行][列]
reg [7:0] brightness_g [0:7][0:7]; // G亮度 [行][列]
reg [7:0] brightness_b [0:7][0:7]; // B亮度 [行][列]

// SPI相关寄存器
reg [2:0] spi_bit_counter;     // SPI位计数器 (0-7)
reg [7:0] spi_byte_buffer;     // SPI字节缓冲器
reg [7:0] spi_data_buffer [0:191]; // SPI数据缓冲器 (192字节)
reg [7:0] spi_byte_counter;    // SPI字节计数器 (0-191)
reg spi_prev_cs_n;             // 前一个CS状态
reg spi_capture_done;          // SPI数据捕获完成标志
reg spi_update_flag;           // SPI更新标志

// 内部信号
reg [7:0] pwm_counter;         // PWM计数器 (0-255)
reg [2:0] row_counter;         // 行计数器 (0-7)
reg [7:0] current_row_data_r;  // 当前行R数据
reg [7:0] current_row_data_g;  // 当前行G数据
reg [7:0] current_row_data_b;  // 当前行B数据

// ===========================================================================
// SPI接收逻辑
// ===========================================================================
always @(posedge spi_sclk or posedge spi_cs_n) begin
    if (spi_cs_n) begin
        // 片选无效时复位SPI计数器
        spi_bit_counter <= 3'b0;
        spi_byte_buffer <= 8'b0;
    end else begin
        // 片选有效时接收数据
        spi_byte_buffer <= {spi_byte_buffer[6:0], spi_mosi};
        if (spi_bit_counter == 3'd7) begin
            // 完整字节接收完成
            spi_data_buffer[spi_byte_counter] <= spi_byte_buffer;
            spi_bit_counter <= 3'b0;
            spi_byte_counter <= spi_byte_counter + 1;
        end else begin
            spi_bit_counter <= spi_bit_counter + 1;
        end
    end
end

// SPI片选变化检测
always @(posedge spi_sclk) begin
    spi_prev_cs_n <= spi_cs_n;
    
    // 检测CS上升沿(传输结束)
    if (spi_prev_cs_n == 1'b0 && spi_cs_n == 1'b1) begin
        spi_capture_done <= 1'b1;
        spi_byte_counter <= 8'b0; // 重置字节计数器
    end
end

// SPI数据捕获完成同步到系统时钟域
reg spi_capture_done_sync1, spi_capture_done_sync2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_capture_done_sync1 <= 1'b0;
        spi_capture_done_sync2 <= 1'b0;
    end else begin
        spi_capture_done_sync1 <= spi_capture_done;
        spi_capture_done_sync2 <= spi_capture_done_sync1;
    end
end

// 检测同步后的捕获完成信号上升沿
wire spi_capture_rising = spi_capture_done_sync2 && !spi_capture_done_sync1;

// SPI数据处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_update_flag <= 1'b0;
        // 初始化所有LED为关闭状态
        for (integer i = 0; i < 8; i = i+1) begin
            for (integer j = 0; j < 8; j = j+1) begin
                brightness_r[i][j] <= 8'h00;
                brightness_g[i][j] <= 8'h00;
                brightness_b[i][j] <= 8'h00;
            end
        end
    end else begin
        // 检测到捕获完成上升沿
        if (spi_capture_rising) begin
            spi_update_flag <= 1'b1;
        end
        
        // 更新亮度数据
        if (spi_update_flag) begin
            spi_update_flag <= 1'b0;
            
            // 解析SPI数据到亮度寄存器
            for (integer i = 0; i < 8; i = i+1) begin
                for (integer j = 0; j < 8; j = j+1) begin
                    // 每个LED对应3字节数据: R, G, B
                    integer index = (i * 24) + (j * 3);
                    brightness_r[i][j] <= spi_data_buffer[index];
                    brightness_g[i][j] <= spi_data_buffer[index+1];
                    brightness_b[i][j] <= spi_data_buffer[index+2];
                end
            end
        end
    end
end

// ===========================================================================
// LED矩阵驱动逻辑 (与之前相同)
// ===========================================================================
// PWM计数器 (8位 256级)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        pwm_counter <= 8'd0;
    else 
        pwm_counter <= pwm_counter + 1;
end

// 行计数器 (每256个时钟周期切换一行)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        row_counter <= 3'd0;
    else if (pwm_counter == 8'd255) // 在PWM周期结束时切换行
        row_counter <= row_counter + 1;
end

// 行选择译码器 (低有效)
always @(*) begin
    row_sel = 8'hFF; // 默认所有行禁用
    case (row_counter)
        3'd0: row_sel[0] = 1'b0;
        3'd1: row_sel[1] = 1'b0;
        3'd2: row_sel[2] = 1'b0;
        3'd3: row_sel[3] = 1'b0;
        3'd4: row_sel[4] = 1'b0;
        3'd5: row_sel[5] = 1'b0;
        3'd6: row_sel[6] = 1'b0;
        3'd7: row_sel[7] = 1'b0;
    endcase
end

// 亮度数据锁存 (在行切换时更新)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_row_data_r <= 8'hFF;
        current_row_data_g <= 8'hFF;
        current_row_data_b <= 8'hFF;
    end
    else if (pwm_counter == 8'd255) begin
        // 锁存新行的RGB数据
        current_row_data_r <= {
            brightness_r[row_counter][7] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][6] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][5] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][4] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][3] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][2] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][1] > pwm_counter ? 1'b0 : 1'b1,
            brightness_r[row_counter][0] > pwm_counter ? 1'b0 : 1'b1
        };
        
        current_row_data_g <= {
            brightness_g[row_counter][7] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][6] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][5] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][4] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][3] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][2] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][1] > pwm_counter ? 1'b0 : 1'b1,
            brightness_g[row_counter][0] > pwm_counter ? 1'b0 : 1'b1
        };
        
        current_row_data_b <= {
            brightness_b[row_counter][7] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][6] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][5] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][4] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][3] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][2] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][1] > pwm_counter ? 1'b0 : 1'b1,
            brightness_b[row_counter][0] > pwm_counter ? 1'b0 : 1'b1
        };
    end
end

// PWM输出生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        red_out   <= 8'hFF;
        green_out <= 8'hFF;
        blue_out  <= 8'hFF;
    end
    else begin
        red_out   <= current_row_data_r;
        green_out <= current_row_data_g;
        blue_out  <= current_row_data_b;
    end
end

endmodule