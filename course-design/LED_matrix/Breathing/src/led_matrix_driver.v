module led_matrix_top (
    input clk,          // 系统时钟 (50MHz)
    input rst,        // 异步复位 (低有效)
    output [7:0] led_row,   // 行选择 (低有效)
    output [7:0] led_col_r,   // R列输出 (低有效)
    output [7:0] led_col_g, // G列输出 (低有效)
    output [7:0] led_col_b   // B列输出 (低有效)
);

// ================== 呼吸灯控制部分 ================== //
localparam BREATHE_PERIOD = 28'd5_000_000; // 2秒呼吸周期 (50MHz * 0.1s)
reg [27:0] breathe_counter;
reg breathe_dir;  // 0:递增, 1:递减
reg [7:0] global_brightness;

// 亮度数据阵列（二维数组：8行，每行64位存储8个LED的亮度）
reg [63:0] brightness_r [0:7]; // R亮度 [行][64位数据]
reg [63:0] brightness_g [0:7]; // G亮度 [行][64位数据]
reg [63:0] brightness_b [0:7]; // B亮度 [行][64位数据]

// 呼吸灯控制逻辑
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        breathe_counter <= 28'd0;
        breathe_dir <= 0;
        global_brightness <= 8'd0;
    end else begin
        // 呼吸计数器
        breathe_counter <= (breathe_counter == BREATHE_PERIOD - 1) 
                          ? 28'd0 : breathe_counter + 1;
        
        // 亮度方向控制
        if (breathe_counter == BREATHE_PERIOD - 1) begin
            if (breathe_dir == 0) begin
                global_brightness <= (global_brightness == 255) 
                                    ? 254 : global_brightness + 1;
                breathe_dir <= (global_brightness == 254) ? 1 : 0;
            end else begin
                global_brightness <= (global_brightness == 0) 
                                    ? 1 : global_brightness - 1;
                breathe_dir <= (global_brightness == 1) ? 0 : 1;
            end
        end
    end
end

// 生成所有LED的亮度数据
genvar i, j;
generate
    for (i = 0; i < 8; i = i + 1) begin : row_gen
        for (j = 0; j < 8; j = j + 1) begin : col_gen
            always @(posedge clk or negedge rst) begin
                if (!rst) begin
                    brightness_r[i][j*8 +: 8] <= 8'd0;
                    brightness_g[i][j*8 +: 8] <= 8'd0;
                    brightness_b[i][j*8 +: 8] <= 8'd0;
                end else begin
                    brightness_r[i][j*8 +: 8] <= global_brightness;
                    brightness_g[i][j*8 +: 8] <= global_brightness;
                    brightness_b[i][j*8 +: 8] <= global_brightness;
                end
            end
        end
    end
endgenerate

// ================== LED驱动部分 ================== //
// 内部信号定义
reg [7:0] pwm_counter;         // PWM计数器 (0-255)
reg [2:0] row_counter;         // 行计数器 (0-7)
reg [63:0] current_row_r;      // 当前行R亮度数据（64位）
reg [63:0] current_row_g;      // 当前行G亮度数据（64位）
reg [63:0] current_row_b;      // 当前行B亮度数据（64位）

// PWM计数器 (8位 256级)
always @(posedge clk or negedge rst) begin
    if (!rst) 
        pwm_counter <= 8'd0;
    else 
        pwm_counter <= pwm_counter + 1;
end

// 行计数器 (每256个时钟周期切换一行)
always @(posedge clk or negedge rst) begin
    if (!rst) 
        row_counter <= 3'd0;
    else if (pwm_counter == 8'd255) // 在PWM周期结束时切换行
        row_counter <= row_counter + 1;
end

// 行选择译码器 (低有效)
assign led_row = ~(8'b1 << row_counter);

// 亮度数据锁存 (在行切换时更新)
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_row_r <= 64'd0;
        current_row_g <= 64'd0;
        current_row_b <= 64'd0;
    end
    else if (pwm_counter == 8'd255) begin
        // 锁存新行的RGB数据
        current_row_r <= brightness_r[row_counter];
        current_row_g <= brightness_g[row_counter];
        current_row_b <= brightness_b[row_counter];
    end
end

// PWM输出生成
reg [7:0] col_r;
reg [7:0] col_g;
reg [7:0] col_b;
integer col;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        col_r <= 8'hFF;
        col_g <= 8'hFF;
        col_b <= 8'hFF;
    end
    else begin
        // 比较每个LED的亮度值与PWM计数器
        for (col = 0; col < 8; col = col + 1) begin
            // R列
            if (current_row_r[col*8 +: 8] > pwm_counter)
                col_r[col] <= 1'b0; // 点亮
            else
                col_r[col] <= 1'b1; // 熄灭
            
            // G列
            if (current_row_g[col*8 +: 8] > pwm_counter)
                col_g[col] <= 1'b0; // 点亮
            else
                col_g[col] <= 1'b1; // 熄灭
            
            // B列
            if (current_row_b[col*8 +: 8] > pwm_counter)
                col_b[col] <= 1'b0; // 点亮
            else
                col_b[col] <= 1'b1; // 熄灭
        end
    end
end

assign led_col_r = col_r;
assign led_col_g = col_g;
assign led_col_b = col_b;

endmodule