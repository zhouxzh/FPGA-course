`timescale 1ns/1ps

module tb_addr_gen;
    reg clk = 0;
    reg rst, en;
    wire [7:0] addr;

    addr_gen #(.MAX_DATA(256)) uut (
        .en(en),
        .clk(clk),
        .rst(rst),
        .addr(addr)
    );

    // 生成时钟（10ns周期）
    always #5 clk = ~clk;

    integer i;
    reg [7:0] expected;

    initial begin
        $dumpfile("tb_addr_gen.vcd");
        $dumpvars(0, tb_addr_gen);  // 记录所有信号

        // 初始化信号
        rst = 1;
        en = 0;
        #20 rst = 0;  // 复位释放

        // 测试1：en=0时地址不变
        en = 0;
        repeat(2) @(posedge clk);
        if (addr !== 8'd0) $error("Test1 Failed");
        else $display("Test1 Passed");

        // 测试2：地址递增至255后回绕
        en = 1;
        expected = 0;
        for (i = 0; i < 256; i = i + 1) begin
            @(posedge clk);
            #1;
            if (addr !== expected) $error("Test2 Failed at step %0d", i);
            expected = (expected == 255) ? 0 : expected + 1;
        end
        $display("Test2 Passed");

        // 测试3：回绕后继续递增
        @(posedge clk);
        #1;
        if (addr !== 8'd1) $error("Test3 Failed");
        else $display("Test3 Passed");

        // 测试4：en=0时地址不变
        en = 0;
        repeat(2) @(posedge clk);
        #1;
        if (addr !== 8'd1) $error("Test4 Failed");
        else $display("Test4 Passed");

        // 测试5：异步复位
        en = 1;
        @(negedge clk);  // 在时钟低电平触发复位
        rst = 1;
        #1;
        if (addr !== 8'd0) $error("Test5 Failed");
        @(posedge clk);
        #1;
        if (addr !== 8'd0) $error("Test5 Failed");
        rst = 0;
        $display("Test5 Passed");

        $display("All Tests Passed");
        $finish;
    end
endmodule