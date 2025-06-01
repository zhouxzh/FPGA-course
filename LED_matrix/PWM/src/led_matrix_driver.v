module led_matrix_driver (
    input clk,          // 系统时钟 (建议50MHz)
    input rst_n,        // 异步复位 (低有效)
    // 亮度数据输入 (每个LED的RGB亮度)
    input [7:0] brightness_r [0:7][0:7], // R亮度 [行][列]
    input [7:0] brightness_g [0:7][0:7], // G亮度 [行][列]
    input [7:0] brightness_b [0:7][0:7], // B亮度 [行][列]
    // LED阵列输出信号
    output reg [7:0] row_sel,   // 行选择 (低有效)
    output reg [7:0] red_out,   // R列输出 (低有效)
    output reg [7:0] green_out, // G列输出 (低有效)
    output reg [7:0] blue_out   // B列输出 (低有效)
);

// 内部信号定义
reg [7:0] pwm_counter;         // PWM计数器 (0-255)
reg [2:0] row_counter;         // 行计数器 (0-7)
reg [7:0] current_row_data_r;  // 当前行R数据
reg [7:0] current_row_data_g;  // 当前行G数据
reg [7:0] current_row_data_b;  // 当前行B数据

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