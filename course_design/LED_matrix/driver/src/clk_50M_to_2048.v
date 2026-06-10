module clk_50M_to_2048 (
    input  wire clk_50M,   // 50MHz输入时钟
    input  wire rst_n,     // 异步复位（低电平有效）
    output wire clk_2048   // 2048Hz输出时钟
);

// 分频系数定义 - 改为 parameter 以便在测试中重定义
parameter N = 32'd24_414;  // 50,000,000 / 2,048 ≈ 24,414
// parameter N = 24;

reg [31:0] counter;         // 分频计数器
reg        clk_out_reg;     // 输出寄存器

// 计数器逻辑
always @(posedge clk_50M or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        clk_out_reg <= 0;
    end else begin
        if (counter == N - 1) begin
            counter <= 0;
            clk_out_reg <= ~clk_out_reg;  // 翻转输出
        end else begin
            counter <= counter + 1;
        end
    end
end

assign clk_2048 = clk_out_reg;

endmodule