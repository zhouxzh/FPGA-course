module Top;
    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    wire sclk, mosi, cs, ready;
    
    // LED数据存储
    reg [23:0] led_mem [0:63]; // 64个24位RGB值
    
    // 地址和数据总线
    reg [5:0] current_addr;
    reg [23:0] current_rgb;
    
    // 实例化SPI控制器
    LED_SPI_Controller spi_ctrl (
        .clk(clk),
        .rst(rst),
        .start(start),
        .led_addr(current_addr),
        .rgb_data(current_rgb),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .ready(ready)
    );
    
    // 时钟生成 (50MHz)
    always #10 clk = ~clk;
    
    // 初始化LED数据（示例：对角线上红色）
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            if (i % 9 == 0) // 对角线上的LED
                led_mem[i] = {8'hFF, 8'h00, 8'h00}; // 红色
            else
                led_mem[i] = {8'h00, 8'h00, 8'h00}; // 关闭
        end
    end
    
    // 主控制状态机
    reg [1:0] ctrl_state;
    localparam IDLE = 0;
    localparam SEND = 1;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ctrl_state <= IDLE;
            start <= 0;
            current_addr <= 0;
        end else begin
            case (ctrl_state)
                IDLE: begin
                    if (ready) begin
                        current_addr <= 0;
                        current_rgb <= led_mem[0];
                        start <= 1;
                        ctrl_state <= SEND;
                    end
                end
                
                SEND: begin
                    start <= 0;
                    
                    if (ready && (current_addr < 63)) begin
                        current_addr <= current_addr + 1;
                        current_rgb <= led_mem[current_addr + 1];
                        start <= 1;
                    end
                    else if (current_addr == 63) begin
                        // 全部传输完成，等待1ms后重新开始
                        #1000000; // 1ms延迟
                        current_addr <= 0;
                        current_rgb <= led_mem[0];
                        start <= 1;
                    end
                end
            endcase
        end
    end
    
    // 测试序列
    initial begin
        #100 rst = 0;   // 释放复位
        #1000000 $display("Simulation complete");
        #100 $finish;
    end
endmodule