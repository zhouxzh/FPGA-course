module fifo_tb;
    // 测试参数设置
    parameter MAX_DATA = 4;       // 使用较小深度便于测试
    localparam AWIDTH = $clog2(MAX_DATA);
    
    // 输入信号
    reg clk, rst;
    reg wen, ren;
    reg [7:0] wdata;
    
    // 输出信号
    wire [7:0] rdata;
    wire [AWIDTH:0] count;
    
    // 实例化被测FIFO
    fifo #(.MAX_DATA(MAX_DATA)) dut (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .ren(ren),
        .wdata(wdata),
        .rdata(rdata),
        .count(count)
    );
    
    // 生成时钟（周期10ns）
    initial clk = 0;
    always #5 clk = ~clk;
    
    // 主测试流程
    initial begin
        // 初始化信号
        wen = 0;
        ren = 0;
        wdata = 0;
        rst = 1;
        
        // 复位操作（15ns后释放）
        #15 rst = 0;
        
        // 测试用例1：基本写操作
        $display("\n=== Test 1: Basic write ===");
        wen = 1;
        repeat(MAX_DATA) begin
            wdata = $random;
            @(posedge clk);
            #1;
            $display("Write: 0x%h | Count: %0d", wdata, count);
        end
        wen = 0;
        
        // 验证计数
        if(count !== MAX_DATA)
            $display("Error: Expected count %0d, got %0d", MAX_DATA, count);
        
        // 测试用例2：基本读操作
        $display("\n=== Test 2: Basic read ===");
        ren = 1;
        repeat(MAX_DATA) begin
            @(posedge clk);
            #1;
            $display("Read: 0x%h | Count: %0d", rdata, count);
        end
        ren = 0;
        
        // 验证空状态
        if(count !== 0)
            $display("Error: Expected count 0, got %0d", count);
            
        // 测试用例3：同时读写
        $display("\n=== Test 3: Concurrent R/W ===");
        wen = 1;
        ren = 1;
        repeat(4) begin
            wdata = $random;
            @(posedge clk);
            #1;
            $display("Write: 0x%h | Read: 0x%h | Count: %0d", 
                    wdata, rdata, count);
        end
        wen = 0;
        ren = 0;
        
        // 测试用例4：边界条件测试
        $display("\n=== Test 4: Boundary cases ===");
        
        // 写满测试
        wen = 1;
        repeat(MAX_DATA+2) begin
            wdata = $urandom;
            @(posedge clk);
        end
        wen = 0;
        $display("Overflow count: %0d", count);
        
        // 读空测试
        ren = 1;
        repeat(MAX_DATA+2) @(posedge clk);
        ren = 0;
        $display("Underflow count: %0d", count);
        
        // 结束仿真
        #100;
        $display("\nTestbench completed");
        $finish;
    end
    
    // 波形记录（可选）
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
    end
endmodule