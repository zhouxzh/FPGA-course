module tb;
  reg clk;
  
    // 波形记录（Icarus专用）
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, clk);
  end

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    #300 $finish;         // 运行30个周期后结束
  end


endmodule
