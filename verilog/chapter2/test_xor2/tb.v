module tb (
    input a,
    input b,
    output f
);
top top_inst(a,b,f);

initial begin
      if ($test$plusargs("trace") != 0) begin
         $display("[%0t] Tracing to wave.vcd...\n", $time);
         $dumpfile("wave.vcd");
         $dumpvars();
      end
      $display("[%0t] Model running...\n", $time);
   end

endmodule
