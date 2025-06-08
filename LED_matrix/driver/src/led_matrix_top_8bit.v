module led_matrix_top (
    input clk,          // 系统时钟 (50MHz)
    input rst,          // 异步复位 (低有效)
    output [7:0] led_row,   // 行选择 (低有效)
    output [7:0] led_col_r, // R列输出 (低有效)
    output [7:0] led_col_g, // G列输出 (低有效)
    output [7:0] led_col_b, // B列输出 (低有效)
    input sclk,         // SPI时钟 (从主设备)
    input mosi,         // SPI主出从入
    input cs,            // 片选 (低有效)
    output [1:0] led
);

// wire [1:0] led; //指示灯，led[0]是数据传输，led[1]是复位按键；

assign led[1] = rst;

// =====================================================
// 时钟分频逻辑 (原clk_50M_to_2048)
// =====================================================
parameter N = 32'd24_414;  // 50,000,000 / 2,048 ≈ 24,414
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
// SPI接收逻辑 (原led_spi_slave)
// =====================================================
reg [31:0] spi_shift_reg;   // 32位移位寄存器
reg [4:0] spi_bit_count;    // 位计数器 (0-31)
reg spi_sclk_delayed;       // 延迟sclk用于边沿检测
reg [5:0] spi_addr_reg;     // 地址寄存器
reg [23:0] spi_rgb_reg;     // RGB数据寄存器
reg [1:0] spi_state;        // 状态机

// 颜色存储阵列
reg [7:0] red [0:63];   // 红色分量
reg [7:0] green [0:63]; // 绿色分量
reg [7:0] blue [0:63];  // 蓝色分量
reg spi_data_valid;      // 数据有效信号

// 状态定义
localparam SPI_IDLE = 2'b00;
localparam SPI_RECEIVE = 2'b01;
localparam SPI_UPDATE = 2'b10;
localparam SPI_FINISHED = 2'b11;

// 边沿检测：检测sclk上升沿
wire sclk_rising = (sclk && !spi_sclk_delayed);

// 初始化存储器
integer i;
initial begin
    for (i = 0; i < 64; i = i + 1) begin
        red[i] = 8'h00;
        green[i] = 8'h00;
        blue[i] = 8'h00;
    end
end

// 主状态机
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        spi_state <= SPI_IDLE;
        spi_shift_reg <= 32'b0;
        spi_bit_count <= 0;
        spi_data_valid <= 0;
        spi_sclk_delayed <= 0;
        spi_addr_reg <= 6'b0;
        spi_rgb_reg <= 24'b0;
    end else begin
        spi_sclk_delayed <= sclk;  // 延迟sclk用于边沿检测
        spi_data_valid <= 0;        // 默认数据有效信号为低
        
        case (spi_state)
            SPI_IDLE: begin
                spi_bit_count <= 0;
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
                // 更新LED颜色
                red[spi_addr_reg] <= spi_rgb_reg[23:16];
                green[spi_addr_reg] <= spi_rgb_reg[15:8];
                blue[spi_addr_reg] <= spi_rgb_reg[7:0];
                spi_data_valid <= 1;  // 置位数据有效信号
                
                if (cs) begin
                    spi_state <= SPI_IDLE;
                end
            end
        endcase
    end
end

assign led[0] = spi_data_valid;

// =====================================================
// LED驱动逻辑 (原led_driver)
// =====================================================
// 亮度存储阵列
// reg [63:0] brightness_r [0:7]; // R亮度 [行][64位]
// reg [63:0] brightness_g [0:7]; // G亮度 [行][64位]
// reg [63:0] brightness_b [0:7]; // B亮度 [行][64位]

// 生成亮度数据
// genvar row, col;
// generate
//     for (row = 0; row < 8; row = row + 1) begin : row_gen
//         for (col = 0; col < 8; col = col + 1) begin : col_gen
//             always @(posedge clk_2048 or negedge rst) begin
//                 if (!rst) begin
//                     brightness_r[row][col*8 +: 8] <= 8'd0;
//                     brightness_g[row][col*8 +: 8] <= 8'd0;
//                     brightness_b[row][col*8 +: 8] <= 8'd0;
//                 end else begin
//                     brightness_r[row][col*8 +: 8] <= red[row*8+col];
//                     brightness_g[row][col*8 +: 8] <= green[row*8+col];
//                     brightness_b[row][col*8 +: 8] <= blue[row*8+col];
//                 end
//             end
//         end
//     end
// endgenerate

wire [63:0] brightness_r [0:7]; // R亮度 [行][64位]
wire [63:0] brightness_g [0:7]; // G亮度 [行][64位]
wire [63:0] brightness_b [0:7]; // B亮度 [行][64位]

genvar row, col;
generate
    for (row = 0; row < 8; row = row + 1) begin : row_gen
        for (col = 0; col < 8; col = col + 1) begin : col_gen
            assign brightness_r[row][col*8 +: 8] = red[row*8+col];
            assign brightness_g[row][col*8 +: 8] = green[row*8+col];
            assign brightness_b[row][col*8 +: 8] = blue[row*8+col];
        end
    end
endgenerate

// LED驱动内部信号
reg [7:0] driver_pwm_counter;    // PWM计数器 (0-255)
reg [2:0] driver_row_counter;    // 行计数器 (0-7)
reg [63:0] current_row_r;        // 当前行R亮度数据
reg [63:0] current_row_g;        // 当前行G亮度数据
reg [63:0] current_row_b;        // 当前行B亮度数据
reg [7:0] driver_col_r;          // R列输出
reg [7:0] driver_col_g;          // G列输出
reg [7:0] driver_col_b;          // B列输出

// PWM计数器 (8位 256级)
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) 
        driver_pwm_counter <= 8'd0;
    else 
        driver_pwm_counter <= driver_pwm_counter + 1;
end

// 行计数器
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) 
        driver_row_counter <= 3'd0;
    else if (driver_pwm_counter == 8'd255) 
        driver_row_counter <= driver_row_counter + 1;
end

// 行选择译码器 (低有效)
assign led_row = ~(8'b1 << driver_row_counter);

// 亮度数据锁存 (行切换时更新)
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) begin
        current_row_r <= 64'd0;
        current_row_g <= 64'd0;
        current_row_b <= 64'd0;
    end
    else if (driver_pwm_counter == 8'd255) begin
        current_row_r <= brightness_r[driver_row_counter];
        current_row_g <= brightness_g[driver_row_counter];
        current_row_b <= brightness_b[driver_row_counter];
    end
end

// PWM输出生成
integer driver_col;
always @(posedge clk_2048 or negedge rst) begin
    if (!rst) begin
        driver_col_r <= 8'hFF;
        driver_col_g <= 8'hFF;
        driver_col_b <= 8'hFF;
    end
    else begin
        for (driver_col = 0; driver_col < 8; driver_col = driver_col + 1) begin
            // R列比较
            driver_col_r[driver_col] <= 
                (current_row_r[driver_col*8 +: 8] > driver_pwm_counter) ? 1'b0 : 1'b1;
            
            // G列比较
            driver_col_g[driver_col] <= 
                (current_row_g[driver_col*8 +: 8] > driver_pwm_counter) ? 1'b0 : 1'b1;
            
            // B列比较
            driver_col_b[driver_col] <= 
                (current_row_b[driver_col*8 +: 8] > driver_pwm_counter) ? 1'b0 : 1'b1;
        end
    end
end

// 输出列信号
assign led_col_r = driver_col_r;
assign led_col_g = driver_col_g;
assign led_col_b = driver_col_b;

endmodule