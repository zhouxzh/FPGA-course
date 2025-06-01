module led_matrix_top (
    input clk,          // 系统时钟 (50MHz)
    input rst_n,        // 异步复位 (低有效)
    output [7:0] row_sel,   // 行选择 (低有效)
    output [7:0] red_out,   // R列输出 (低有效)
    output [7:0] green_out, // G列输出 (低有效)
    output [7:0] blue_out   // B列输出 (低有效)
);

// 呼吸灯控制参数
localparam BREATHE_PERIOD = 28'd100_000_000; // 2秒呼吸周期 (50MHz * 2s)
reg [27:0] breathe_counter;
reg breathe_dir;  // 0:递增, 1:递减
reg [7:0] global_brightness;

// 亮度数据阵列
wire [7:0] brightness_r [0:7][0:7];
wire [7:0] brightness_g [0:7][0:7];
wire [7:0] brightness_b [0:7][0:7];

// 呼吸灯控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
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
            assign brightness_r[i][j] = global_brightness;
            assign brightness_g[i][j] = global_brightness;
            assign brightness_b[i][j] = global_brightness;
        end
    end
endgenerate

// LED矩阵驱动实例化
led_matrix_driver driver (
    .clk(clk),
    .rst_n(rst_n),
    .brightness_r(brightness_r),
    .brightness_g(brightness_g),
    .brightness_b(brightness_b),
    .row_sel(row_sel),
    .red_out(red_out),
    .green_out(green_out),
    .blue_out(blue_out)
);

endmodule