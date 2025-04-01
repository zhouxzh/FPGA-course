  #include "Vour.h"
  using namespace sc_core;
  int sc_main(int argc, char** argv) {
      Verilated::commandArgs(argc, argv);
      sc_clock clk{"clk", 10, SC_NS, 0.5, 3, SC_NS, true};
      Vour* top = new Vour{"top"};
      top->clk(clk);
      while (!Verilated::gotFinish()) { sc_start(1, SC_NS); }
      delete top;
      return 0;
  }
