#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include "verilated_vcd_c.h" // 生成vcd文件使用
#include "Vtop.h"
#include "verilated.h"

int main (int argc, char **argv) {
    if (false && argc && argv) {}
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    std::unique_ptr<Vtop> top{new Vtop{contextp.get()}};
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true); // 生成波形文件使用，打开追踪功能
    VerilatedVcdC* ftp = new VerilatedVcdC; // vcd对象指针
    top->trace(ftp, 0); // 0层
    ftp->open("wave.vcd"); //设置输出的文件wave.vcd

    int flag = 0;

    while (!contextp->gotFinish() && ++flag < 20) {
        int a = rand() & 1;
        int b = rand() & 1;
        top->a = a;
        top->b = b;
        top->eval();
        printf("a = %d, b = %d, f = %d\n", a, b, top->f);
        assert(top->f == (a ^ b));

        contextp->timeInc(1); // 时间+1，推动仿真时间
 
        ftp->dump(contextp->time()); // dump wave
    }

    top->final();

    ftp->close(); // 必须有

    return 0;
}