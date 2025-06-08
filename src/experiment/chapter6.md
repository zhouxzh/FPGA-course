# 实验6；PS端MIO的使用

---

#### **概述**
- **实验工程**：Vivado工程名为“ps_mio”（注：AX7Z020/AX7Z010开发板无此工程）。
- **实验目的**：通过MIO控制PS端外设（如LED、按键），掌握MIO与EMIO的基础操作及中断配置。

---

#### **MIO与GPIO结构**
1. **MIO特性**：
   - 共54个引脚，分两个BANK：
     - BANK0：16引脚
     - BANK1：38引脚
   - **电压选择**：需根据外设电压要求配置BANK0/BANK1电压。
   - 支持外设：SPI、I2C、UART、GPIO等，可通过Vivado配置信号导出至MIO或通过EMIO连接至PL端。

2. **GPIO BANK分布**（UG585文档）：
   - **BANK0**：32信号（对应MIO的0-31）
   - **BANK1**：22信号（对应MIO的32-53）
   - **BANK2/BANK3**：64个PL端引脚（每组含输入、输出、使能信号，共192个信号）。

---

#### **实验环境与配置**
- **基础工程**：基于“ps_hello”工程修改。
- **硬件连接**：
  - AX7020/AX7010开发板的LED连接至PS端MIO0（AX7020）和MIO13（AX7010）。
  - 按键通过MIO输入触发中断。

---

#### **实验步骤：MIO控制LED闪烁**
1. **Vivado配置**：
   - 打开GPIO MIO功能，配置引脚为输出模式。
   - 生成比特流并导出至SDK。

2. **SDK开发**：
   - 导入Xilinx示例工程（`ps7_gpio_0`）。
   - 代码流程：
     ```c
     GPIO初始化 → 设置LED方向 → 循环控制LED电平翻转
     ```

---

#### **按键中断实现**
1. **中断寄存器配置**（关键寄存器）：
   - **INT_TYPE**：中断类型（电平/边沿敏感）
   - **INT_POLARITY**：极性（低电平/下降沿 或 高电平/上升沿）
   - **INT_ANY**：边沿触发方式（需INT_TYPE设为边沿敏感）。
   - **操作流程**：
     ```c
     初始化GPIO → 设置按键输入/LED输出方向 → 配置中断类型（上升沿触发） → 使能中断
     ```

2. **中断服务程序设计**：
   - **主函数**：设置中断优先级（操作`ICDIPR`/`ICDICFR`寄存器）。
   - **中断服务函数**：
     ```c
     判断中断状态 → 清除中断标志 → 翻转LED状态（按键按下时触发）
     ```

---

#### **关键代码逻辑**
1. **初始化与中断配置**：
   ```c
   IntrInitFunctions();          // 初始化中断控制器
   XScuGic_SetPriorityTriggerType(IntcInstance, GPIO_INTR_ID, 0xA0, 0x3); // 设置优先级与触发方式
   ```

2. **中断服务程序**：
   ```c
   void GpioHandler(void) {
       if (XGpio_InterruptGetStatus(GpioInstance)) { // 读取中断状态
           XGpio_InterruptClear(GpioInstance, 1);    // 清除中断标志
           KEY_FLAG = 1;                             // 更新按键状态
       }
   }
   ```

---

#### **注意事项**
1. **硬件差异**：AX7020与AX7010的LED连接至不同MIO引脚，需核对原理图。
2. **电压匹配**：确保MIO BANK0/BANK1电压与外设一致。
3. **中断冲突**：避免多个中断共享相同优先级或通道。

---

通过本实验，可掌握PS端MIO的GPIO控制与中断配置方法，为复杂外设开发奠定基础。
