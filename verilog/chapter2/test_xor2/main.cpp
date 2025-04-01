#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include "Vtb.h"
#include "verilated.h"

int main (int argc, char **argv) {
    if (false && argc && argv) {}
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    std::unique_ptr<Vtb> tb{new Vtb{contextp.get()}};
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true); // 生成波形文件使用，打开追踪功能

    int flag = 0;

    while (!contextp->gotFinish() && ++flag < 20) {
        int a = rand() & 1;
        int b = rand() & 1;
        tb->a = a;
        tb->b = b;
        tb->eval();
        printf("a = %d, b = %d, f = %d\n", a, b, tb->f);
        assert(tb->f == (a ^ b));

        contextp->timeInc(1); // 时间+1，推动仿真时间
    }

    tb->final();

    return 0;
}