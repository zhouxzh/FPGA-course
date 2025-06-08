module Marquee (
    input clk,      // 50MHz时钟输入
    input rst, //复位功能     
    output [1:0] led, //指示灯
    output reg [7:0] led_row,  // 行控制信号（高电平有效）
    output reg [7:0] led_col_r,   // 列控制信号（低电平有效）
    output reg [7:0] led_col_g,   // 列控制信号（低电平有效）
    output reg [7:0] led_col_b   // 列控制信号（低电平有效）

);

// 分频器参数（Hz）
parameter DIVIDER = 25_000_000;
// 状态定义
parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3,
          S4 = 3'd4, S5 = 3'd5, S6 = 3'd6, S7 = 3'd7;

// 消抖参数设置 (50MHz时钟对应20ms)
parameter DEBOUNCE_MS = 20;          // 消抖时间(ms)
parameter CLK_FREQ = 50_000_000;    // 时钟频率(Hz)
localparam DEBOUNCE_CYCLES = (DEBOUNCE_MS * CLK_FREQ) / 1000;

// 按钮同步逻辑
reg [1:0] btn_sync;
always @(posedge clk) btn_sync <= {btn_sync[0], ~rst}; // 注意这里取反

// 消抖计数器逻辑
reg [19:0] debounce_cnt;
reg btn_debounced;

always @(posedge clk) begin
    // 当检测到输入变化时启动计数器
    if(btn_sync[1] != btn_debounced) begin
        if(debounce_cnt == DEBOUNCE_CYCLES) begin
            btn_debounced <= btn_sync[1]; // 更新稳定值
            debounce_cnt <= 0;
        end else begin
            debounce_cnt <= debounce_cnt + 1;
        end
    end else begin
        debounce_cnt <= 0; // 状态未变化时保持清零
    end
end

// 边沿检测逻辑
reg [1:0] edge_detect;
always @(posedge clk) edge_detect <= {edge_detect[0], btn_debounced};
wire btn_pressed = (edge_detect == 2'b10); // 检测下降沿

// 状态转移逻辑
// 8x8 LED状态寄存器
reg [24:0] counter;
reg clk_1hz;
reg [2:0] led_state;
always @(posedge clk) begin
    if(btn_pressed) begin  // 有效按键
        counter <= 0;
        clk_1hz <= 0;
        led_row <= 8'b1111_1111;
        led_state <= (led_state == S7) ? S0 : led_state + 1;
        case (led_state)
            S0 : begin
                led_col_r <= 8'b1111_1111; 
                led_col_g <= 8'b1111_1111;
                led_col_b <= 8'b1111_1111;
            end
            S1 : begin
                led_col_r <= 8'b1111_1110; 
                led_col_g <= 8'b1111_1111;
                led_col_b <= 8'b1111_1111;
            end
            S2 : begin
                led_col_r <= 8'b1111_1111; 
                led_col_g <= 8'b1111_1110;
                led_col_b <= 8'b1111_1111;
            end
            S3 : begin
                led_col_r <= 8'b1111_1111; 
                led_col_g <= 8'b1111_1111;
                led_col_b <= 8'b1111_1110;
            end
            S4 : begin
                led_col_r <= 8'b1111_1110; 
                led_col_g <= 8'b1111_1110;
                led_col_b <= 8'b1111_1111;
            end
            S5 : begin
                led_col_r <= 8'b1111_1110; 
                led_col_g <= 8'b1111_1111;
                led_col_b <= 8'b1111_1110;
            end
            S6 : begin
                led_col_r <= 8'b1111_1111; 
                led_col_g <= 8'b1111_1110;
                led_col_b <= 8'b1111_1110;
            end
            S7 : begin
                led_col_r <= 8'b1111_1110; 
                led_col_g <= 8'b1111_1110;
                led_col_b <= 8'b1111_1110;
            end
        endcase
    end
    else if (counter == DIVIDER - 1) begin
        counter <= 0;
        clk_1hz <= ~clk_1hz;
        led_col_r <= {led_col_r[6:0], led_col_r[7]};  // 循环左移
        led_col_g <= {led_col_g[6:0], led_col_g[7]};  // 循环左移
        led_col_b <= {led_col_b[6:0], led_col_b[7]};  // 循环左移
    end 
    else begin
        counter <= counter + 1;
    end
end

assign led[0] = rst;
assign led[1] = clk_1hz;

endmodule
