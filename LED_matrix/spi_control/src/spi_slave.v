module LED_SPI_Receiver (
    input clk,           // 系统时钟 (e.g., 50MHz)
    input rst,           // 异步复位
    input sclk,          // SPI时钟 (从主设备)
    input mosi,          // SPI主出从入
    input cs,            // 片选 (低有效)
    output reg [7:0] red [0:7][0:7],   // 红色分量存储
    output reg [7:0] green [0:7][0:7], // 绿色分量存储
    output reg [7:0] blue [0:7][0:7],  // 蓝色分量存储
    output reg data_valid,             // 数据有效信号
    output reg [5:0] last_addr         // 最后更新的地址
);

// 内部寄存器和状态定义
reg [31:0] shift_reg;   // 32位移位寄存器
reg [4:0] bit_count;    // 位计数器 (0-31)
reg sclk_delayed;       // 用于边沿检测的延迟sclk
reg [5:0] addr_reg;     // 地址寄存器
reg [23:0] rgb_reg;     // RGB数据寄存器
reg [1:0] state;        // 状态机

// SPI模式0参数
localparam IDLE = 2'b00;
localparam RECEIVE = 2'b01;
localparam UPDATE = 2'b10;

// 边沿检测：检测sclk上升沿
wire sclk_rising = (sclk && !sclk_delayed);

// 地址解码：将6位地址转换为8x8行列
wire [2:0] row = addr_reg[5:3];  // 高3位为行地址 (0-7)
wire [2:0] col = addr_reg[2:0];  // 低3位为列地址 (0-7)

// 主状态机
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        shift_reg <= 32'b0;
        bit_count <= 0;
        data_valid <= 0;
        sclk_delayed <= 0;
        addr_reg <= 6'b0;
        rgb_reg <= 24'b0;
        last_addr <= 6'b0;
        
        // 初始化所有LED为关闭状态
        for (int i = 0; i < 8; i = i + 1) begin
            for (int j = 0; j < 8; j = j + 1) begin
                red[i][j] <= 8'h00;
                green[i][j] <= 8'h00;
                blue[i][j] <= 8'h00;
            end
        end
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
                        addr_reg <= shift_reg[30:25]; // 提取地址位[30:25]
                        rgb_reg <= shift_reg[23:0];   // 提取RGB数据[23:0]
                        state <= UPDATE;
                    end
                end
                
                if (cs) begin  // 片选失效，中断接收
                    state <= IDLE;
                end
            end
            
            UPDATE: begin
                // 更新LED矩阵数据
                if (row < 8 && col < 8) begin
                    red[row][col]   <= rgb_reg[23:16];  // R分量
                    green[row][col] <= rgb_reg[15:8];   // G分量
                    blue[row][col]  <= rgb_reg[7:0];    // B分量
                end
                
                last_addr <= addr_reg;  // 存储最后更新的地址
                data_valid <= 1;        // 置位数据有效信号
                state <= IDLE;           // 返回空闲状态
            end
        endcase
    end
end

endmodule