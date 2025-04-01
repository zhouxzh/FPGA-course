# PS定时器中断实验

### 实验概述
- **实验 Vivado 工程名称**: `ps_timer`
- **目标**: 使用 ZYNQ 的 CPU Private Timer（私有定时器）实现定时器中断，每隔1秒触发一次中断，并在中断处理函数中打印信息，30秒后结束。

### ZYNQ 中断系统介绍
- **中断类型**:
  1. **SGI** (软件生成中断): 16个端口
  2. **PPI** (CPU 私有外设中断): 5个
  3. **SPI** (共享外设中断): 44个来自PS端，16个来自PL端
- **中断控制器 (GIC)**:
  - **ICC**: 控制中断
  - **ICD**: 连接SGI和PPI，配置SPI中断

### 中断寄存器介绍
- **ICDICFR**: 配置触发方式，6个寄存器，每个32位，每两位表示一个中断
- **ICDIPR**: 中断优先级寄存器，24个寄存器，每8位代表一个中断
- **ICDIPTR**: CPU选择寄存器，24个寄存器，每8位代表一个中断
- **ICDICER**: 中断关闭寄存器，3个寄存器，每1位代表一个中断
- **ICDISER**: 中断使能寄存器，3个寄存器，每1位代表一个中断

### SDK 程序编写步骤
1. **删除旧的硬件平台信息**：在SDK中删除旧的硬件平台信息文件夹。
2. **重启SDK**：在Vivado中重新运行SDK，生成新的硬件平台信息。
3. **创建新工程**：在SDK中创建新工程，命名为`ps_timer_test`，模板为`Hello World`。
4. **编写代码**：编写代码实现1秒定时器中断，并在中断处理函数中打印信息，30秒后结束。

### 代码示例
以下是一个简单的Xilinx SDK代码示例，用于实现1秒定时器中断：

```c file: ps_timer_test.c
#include "xparameters.h"
#include "xscutimer.h"
#include "xscugic.h"
#include "xil_printf.h"

#define TIMER_LOAD_VALUE (XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ / 2) // 1秒中断

XScuTimer Timer;
XScuGic InterruptController;

void TimerInterruptHandler(void *CallBackRef) {
    static int count = 0;
    XScuTimer *TimerInstance = (XScuTimer *)CallBackRef;
    XScuTimer_ClearInterruptStatus(TimerInstance);

    if (count < 30) {
        xil_printf("Timer interrupt occurred! Count: %d\n", count);
        count++;
    } else {
        XScuTimer_Stop(TimerInstance);
        xil_printf("Timer stopped after 30 seconds.\n");
    }
}

int main() {
    XScuTimer_Config *TimerConfig;
    XScuGic_Config *GicConfig;

    // Initialize Timer
    TimerConfig = XScuTimer_LookupConfig(XPAR_PS7_SCUTIMER_0_DEVICE_ID);
    XScuTimer_CfgInitialize(&Timer, TimerConfig, TimerConfig->BaseAddr);
    XScuTimer_LoadTimer(&Timer, TIMER_LOAD_VALUE);
    XScuTimer_EnableAutoReload(&Timer);
    XScuTimer_Start(&Timer);

    // Initialize Interrupt Controller
    GicConfig = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
    XScuGic_CfgInitialize(&InterruptController, GicConfig, GicConfig->CpuBaseAddress);

    // Connect Timer Interrupt
    XScuGic_Connect(&InterruptController, XPAR_SCUTIMER_INTR, 
                    (Xil_ExceptionHandler)TimerInterruptHandler, &Timer);

    // Enable Timer Interrupt
    XScuGic_Enable(&InterruptController, XPAR_SCUTIMER_INTR);

    // Enable Interrupts
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, 
                                 (Xil_ExceptionHandler)XScuGic_InterruptHandler, 
                                 &InterruptController);
    Xil_ExceptionEnable();

    while (1) {
        // Main loop
    }

    return 0;
}
```

### 参考文献
- **UG585**: Zynq-7000 Technical Reference Manual

### 总结
- 本实验通过ZYNQ的私有定时器实现了1秒定时器中断，并在中断处理函数中打印信息，30秒后停止定时器。
- 代码中使用了Xilinx的API函数来控制定时器和中断控制器，开发者可以根据需求进一步修改和扩展。