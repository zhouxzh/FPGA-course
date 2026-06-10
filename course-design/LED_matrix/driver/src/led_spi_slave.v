module led_spi_slave (
    input clk,           // 系统时钟 (e.g., 50MHz)
    input rst,           // 异步复位(低电平有效)
    input sclk,          // SPI时钟 (从主设备)
    input mosi,          // SPI主出从入
    input cs,            // 片选 (低有效)
    output reg [7:0] red [0:63],   // 红色分量存储(一维64元素)
    output reg [7:0] green [0:63], // 绿色分量存储(一维64元素)
    output reg [7:0] blue [0:63],  // 蓝色分量存储(一维64元素)
    output reg data_valid          // 数据有效信号
);

// 内部寄存器和状态定义
reg [31:0] shift_reg;   // 32位移位寄存器
reg [4:0] bit_count;    // 位计数器 (0-31)
reg sclk_delayed;       // 用于边沿检测的延迟sclk
reg [5:0] addr_reg;     // 地址寄存器(直接用作一维索引)
reg [23:0] rgb_reg;     // RGB数据寄存器
reg [1:0] state;        // 状态机

// SPI模式0参数
localparam IDLE = 2'b00;
localparam RECEIVE = 2'b01;
localparam UPDATE = 2'b10;
localparam FINISHED = 2'b11;

// 边沿检测：检测sclk上升沿
wire sclk_rising = (sclk && !sclk_delayed);

// 使用generate初始化存储器
genvar i;
generate
    for (i = 0; i < 64; i = i + 1) begin : INIT_MEM
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                // 初始化单个LED
                red[i] <= 8'h00;
                green[i] <= 8'h00;
                blue[i] <= 8'h00;
            end
            else if (state == FINISHED && addr_reg == i) begin
                // 更新单个LED
                red[i] <= rgb_reg[23:16];   // R分量
                green[i] <= rgb_reg[15:8];  // G分量
                blue[i] <= rgb_reg[7:0];    // B分量
            end
        end
    end
endgenerate

// 主状态机
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= IDLE;
        shift_reg <= 32'b0;
        bit_count <= 0;
        data_valid <= 0;
        sclk_delayed <= 0;
        addr_reg <= 6'b0;
        rgb_reg <= 24'b0;
    end else begin
        sclk_delayed <= sclk;  // 延迟sclk用于边沿检测
        data_valid <= 0;        // 默认数据有效信号为低
        
        case (state)
            IDLE: begin
                bit_count <= 0;
                if (!cs) begin  // 片选激活
                    state <= RECEIVE;
                end
            end
            
            RECEIVE: begin
                if (sclk_rising) begin  // SPI时钟上升沿采样数据
                    shift_reg <= {shift_reg[30:0], mosi};  // 左移并捕获新位
                    bit_count <= bit_count + 1;
                    
                    if (bit_count == 31) begin
                        // 完整32位接收完毕
                        state <= UPDATE;
                    end
                end
                
                if (cs) begin  // 片选失效，中断接收
                    state <= IDLE;
                end
            end
            
            UPDATE: begin
                addr_reg <= shift_reg[29:24]; // 提取地址位[29:24]
                rgb_reg <= shift_reg[23:0];   // 提取RGB数据[23:0]
                state <= FINISHED;           // 转至更新状态
            end

            FINISHED: begin
                // LED更新现在由generate块处理
                data_valid <= 1;        // 置位数据有效信号
                
                if (cs) begin
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule