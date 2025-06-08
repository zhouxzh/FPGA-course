module led_matrix_top (
    input clk,          // 系统时钟 (50MHz)
    input rst,          // 异步复位 (低有效)
    output [7:0] led_row,   // 行选择 (高有效)
    output [7:0] led_col_r, // R列输出 (低有效)
    output [7:0] led_col_g, // G列输出 (低有效)
    output [7:0] led_col_b, // B列输出 (低有效)
    input sclk,         // SPI时钟 (从主设备)
    input mosi,         // SPI主出从入
    input cs,            // 片选 (低有效)
    output [1:0] led
);

assign led[1] = rst;

// =====================================================
// 时钟分频逻辑
// =====================================================
// parameter N = 32'd24_414;  // 50,000,000 / 2,048 ≈ 24,414
// parameter N = 32'd31_250; //50,000,000 / 16 / 10 = 32,250
parameter N = 32'd6_510; //60FPS
// parameter N = 8; //仿真的时候，选用N=8加快仿真速度
reg [31:0] clkgen_counter;      // 分频计数器
reg clk_out_reg;            // 输出寄存器
wire clk_2048;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        clkgen_counter <= 0;
        clk_out_reg <= 0;
    end else begin
        if (clkgen_counter == N - 1) begin
            clkgen_counter <= 0;
            clk_out_reg <= ~clk_out_reg;
        end else begin
            clkgen_counter <= clkgen_counter + 1;
        end
    end
end
assign clk_2048 = clk_out_reg;

// =====================================================
// SPI接收逻辑
// =====================================================
reg [31:0] spi_shift_reg;   // 32位移位寄存器
reg [4:0] spi_bit_count;    // 位计数器 (0-31)
reg [5:0] spi_addr_reg;     // 地址寄存器
reg [23:0] spi_rgb_reg;     // RGB数据寄存器
reg [1:0] spi_state;        // 状态机

// 颜色存储阵列 (修改为4位宽度)
reg [3:0] red [0:63];   // 红色分量 (4位)
reg [3:0] green [0:63]; // 绿色分量 (4位)
reg [3:0] blue [0:63];  // 蓝色分量 (4位)
reg spi_data_valid;      // 数据有效信号

// 状态定义
localparam SPI_IDLE = 2'b00;
localparam SPI_RECEIVE = 2'b01;
localparam SPI_UPDATE = 2'b10;
localparam SPI_FINISHED = 2'b11;

// 边沿检测：检测sclk上升沿
// 两级同步寄存器避免亚稳态
reg [1:0] sync_reg;

// 同步化SPI时钟信号
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sync_reg <= 2'b00;
    end else begin
        sync_reg <= {sync_reg[0], sclk};
    end
end

// 延迟一拍的同步信号
reg sclk_delayed;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sclk_delayed <= 1'b0;
    end else begin
        sclk_delayed <= sync_reg[1];
    end
end

wire sclk_rising = (sync_reg[1] && !sclk_delayed);

// 初始化存储器
integer i;
// 主状态机
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        spi_state <= SPI_IDLE;
        spi_shift_reg <= 32'b0;
        spi_bit_count <= 0;
        spi_data_valid <= 0;
        spi_addr_reg <= 6'b0;
        spi_rgb_reg <= 24'b0;
        for (i = 0; i < 64; i = i + 1) begin
            red[i] <= 4'h0;
            green[i] <= 4'h0;
            blue[i] <= 4'h0;
        end
    end else begin
        case (spi_state)
            SPI_IDLE: begin
                spi_bit_count <= 0;
                spi_data_valid <= 0;        // 默认数据有效信号为低
                if (!cs) begin  // 片选激活
                    spi_state <= SPI_RECEIVE;
                end
            end
            
            SPI_RECEIVE: begin
                if (sclk_rising) begin  // SPI时钟上升沿采样数据
                    spi_shift_reg <= {spi_shift_reg[30:0], mosi};  // 左移并捕获新位
                    spi_bit_count <= spi_bit_count + 1;
                    
                    if (spi_bit_count == 31) begin
                        spi_state <= SPI_UPDATE;
                    end
                end
                
                if (cs) begin  // 片选失效，中断接收
                    spi_state <= SPI_IDLE;
                end
            end
            
            SPI_UPDATE: begin
                spi_addr_reg <= spi_shift_reg[29:24]; // 提取地址位[29:24]
                spi_rgb_reg <= spi_shift_reg[23:0];   // 提取RGB数据[23:0]
                spi_state <= SPI_FINISHED;
            end

            SPI_FINISHED: begin
                // 更新LED颜色 (仅存储高4位)
                red[spi_addr_reg] <= spi_rgb_reg[23:20];   // R高4位
                green[spi_addr_reg] <= spi_rgb_reg[15:12]; // G高4位
                blue[spi_addr_reg] <= spi_rgb_reg[7:4];    // B高4位
                spi_data_valid <= 1;  // 置位数据有效信号
                
                if (cs) begin
                    spi_state <= SPI_IDLE;
                end
            end
        endcase
    end
end

assign led[0] = spi_data_valid;

// LED驱动内部信号
reg [3:0] driver_pwm_counter;    // PWM计数器 (0-15)
reg [2:0] driver_row_counter;    // 行计数器 (0-7)
reg [3:0] current_row_r[7:0];        // 当前行R亮度数据 (32位)
reg [3:0] current_row_g[7:0];        // 当前行G亮度数据
reg [3:0] current_row_b[7:0];        // 当前行B亮度数据
reg [7:0] driver_col_r;          // R列输出
reg [7:0] driver_col_g;          // G列输出
reg [7:0] driver_col_b;          // B列输出

// PWM计数器 (4位 16级)
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) 
        driver_pwm_counter <= 4'd0;
    else 
        driver_pwm_counter <= driver_pwm_counter + 1;
end

// 行计数器
// 行选择译码器 (高有效)
reg [7:0] current_row;

// 亮度数据锁存 (行切换时更新)
integer col;
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) begin
        for (col = 0; col < 8; col = col + 1) begin
            current_row_r[col] <= 0;  
            current_row_r[col] <= 0;
            current_row_r[col] <= 0;
        end
        current_row <= 8'h00;
        driver_row_counter <= 3'd0;
    end
    else if (driver_pwm_counter == 4'hF) begin
        current_row <= 8'h01 << driver_row_counter;
        driver_row_counter <= driver_row_counter + 1;
        case(driver_row_counter)
        0: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col];  
                current_row_g[col] <= green[col];
                current_row_b[col] <= blue[col];
            end
        end
        1: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+8];  
                current_row_g[col] <= green[col+8];
                current_row_b[col] <= blue[col+8];
            end
        end
        2: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+16];  
                current_row_g[col] <= green[col+16];
                current_row_b[col] <= blue[col+16];
            end
        end
        3: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+24];  
                current_row_g[col] <= green[col+24];
                current_row_b[col] <= blue[col+24];
            end
        end
        4: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+32];  
                current_row_g[col] <= green[col+32];
                current_row_b[col] <= blue[col+32];
            end
        end
        5: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+40];  
                current_row_g[col] <= green[col+40];
                current_row_b[col] <= blue[col+40];
            end
        end
        6: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+48];  
                current_row_g[col] <= green[col+48];
                current_row_b[col] <= blue[col+48];
            end
        end
        7: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= red[col+56];  
                current_row_g[col] <= green[col+56];
                current_row_b[col] <= blue[col+56];
            end
        end
        default: begin
            for (col = 0; col < 8; col = col + 1) begin
                current_row_r[col] <= 0;  
                current_row_g[col] <= 0;
                current_row_b[col] <= 0;
            end
        end
        endcase
    end
end

// PWM输出生成 (修改为4位比较)
integer driver_col;
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) begin
        driver_col_r <= 8'hFF;
        driver_col_g <= 8'hFF;
        driver_col_b <= 8'hFF;
    end
    else begin
        for (driver_col = 0; driver_col < 8; driver_col = driver_col + 1) begin
            // 使用PWM计数器的高4位进行比较
            // 列比较 (低有效: 当颜色值 > PWM)
            driver_col_r[driver_col] <= (current_row_r[driver_col] > driver_pwm_counter) ? 1'b0 : 1'b1;  
            driver_col_g[driver_col] <= (current_row_g[driver_col] > driver_pwm_counter) ? 1'b0 : 1'b1;
            driver_col_b[driver_col] <= (current_row_b[driver_col] > driver_pwm_counter) ? 1'b0 : 1'b1;
        end
    end
end

// 输出列信号
assign led_col_r = driver_col_r;
assign led_col_g = driver_col_g;
assign led_col_b = driver_col_b;
assign led_row = current_row;

endmodule