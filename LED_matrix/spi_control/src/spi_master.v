module LED_SPI_Controller (
    input clk,           // 系统时钟 (e.g., 50MHz)
    input rst,           // 异步复位
    input start,         // 发送启动信号
    input [5:0] led_addr, // LED地址 (0-63)
    input [23:0] rgb_data, // RGB数据 {R[7:0], G[7:0], B[7:0]}
    output reg sclk,     // SPI时钟
    output reg mosi,     // SPI主输出
    output reg cs,       // 片选 (低有效)
    output reg ready     // 控制器就绪信号
);

// 状态定义
localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam SEND = 2'b10;
reg [1:0] state;

// 内部寄存器
reg [31:0] shift_reg;   // 32位移位寄存器 {8'b0, led_addr, rgb_data}
reg [4:0] bit_count;    // 位计数器 (0-31)
reg [5:0] addr_counter; // 地址计数器 (0-63)
reg clk_div;            // SPI时钟分频器

// 状态机
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        sclk <= 1'b0;
        mosi <= 1'b0;
        cs <= 1'b1;      // 片选无效
        ready <= 1'b1;   // 初始就绪
        bit_count <= 0;
        addr_counter <= 0;
        clk_div <= 0;
    end else begin
        case (state)
            IDLE: begin
                sclk <= 1'b0;   // 模式0空闲低电平
                mosi <= 1'b0;
                cs <= 1'b1;
                bit_count <= 0;
                addr_counter <= 0;
                ready <= 1'b1;
                
                if (start) begin
                    state <= LOAD;
                    ready <= 1'b0;
                end
            end
            
            LOAD: begin
                // 加载数据: {8'b0, led_addr, rgb_data}
                shift_reg <= {8'b0, led_addr, rgb_data};
                cs <= 1'b0;     // 激活片选
                state <= SEND;
            end
            
            SEND: begin
                clk_div <= ~clk_div;  // 2分频
                
                if (clk_div) begin  // 系统时钟上升沿 (SPI时钟上升沿)
                    sclk <= 1'b1;
                end else begin       // 系统时钟下降沿 (SPI时钟下降沿)
                    sclk <= 1'b0;
                    
                    if (bit_count < 31) begin
                        // 数据移位(SPI模式0在下降沿改变数据)
                        mosi <= shift_reg[31];     // 输出MSB
                        shift_reg <= shift_reg << 1; // 左移
                        bit_count <= bit_count + 1; // 位计数增加
                    end
                    else begin
                        // 当前LED数据传输完成
                        bit_count <= 0;
                        addr_counter <= addr_counter + 1;
                        
                        if (addr_counter == 63) begin
                            // 所有LED传输完成
                            state <= IDLE;
                            cs <= 1'b1;
                        end else begin
                            // 加载下一个LED数据
                            state <= LOAD;
                        end
                    end
                end
            end
        endcase
    end
end

endmodule