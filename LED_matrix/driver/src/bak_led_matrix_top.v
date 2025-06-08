module led_matrix_top (
    input clk,          // 系统时钟 (50MHz)
    input rst,        // 异步复位 (低有效)
    output [7:0] led_row,   // 行选择 (低有效)
    output [7:0] led_col_r,   // R列输出 (低有效)
    output [7:0] led_col_g, // G列输出 (低有效)
    output [7:0] led_col_b,   // B列输出 (低有效)
    input sclk,          // SPI时钟 (从主设备)
    input mosi,          // SPI主出从入
    input cs             // 片选 (低有效)
);


wire clk_2048;   // 2048Hz输出时钟

clk_50M_to_2048 clk_dut (
    .clk_50M(clk), 
    .rst_n(rst), 
    .clk_2048(clk_2048)
);
    
wire data_valid;
wire [7:0] red [0:63];   // 红色分量存储(一维64元素)
wire [7:0] green [0:63]; // 绿色分量存储(一维64元素)
wire [7:0] blue [0:63];  // 蓝色分量存储(一维64元素)
// 实例化SPI接收器
led_spi_slave spi (
    .clk(clk),
    .rst(rst),
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs),
    .red(red),
    .green(green),
    .blue(blue),
    .data_valid(data_valid)
);

// 实例化待测设计
led_driver driver (
    .clk(clk_2048),
    .rst(rst),
    .red(red),
    .green(green),
    .blue(blue),
    .led_row(led_row),
    .led_col_r(led_col_r),
    .led_col_g(led_col_g),
    .led_col_b(led_col_b)
);


endmodule