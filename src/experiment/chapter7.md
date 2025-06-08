# 实验7：PS端EMIO操作与PL端外设控制  

---

#### **概述**  
- **实验目的**：通过EMIO实现PS控制PL端LED灯及按键中断，掌握EMIO与PL引脚交互的方法。  
- **实验工程**：Vivado工程名为“ps_emio”，基于“ps_hello”工程修改。  
- **核心概念**：  
  - **EMIO**：PS端通过BANK2/BANK3扩展的64个引脚，用于连接PL端外设，编号从54开始（MIO占用0-53）。  
  - **与MIO区别**：EMIO需通过PL端引脚映射，需生成FPGA比特流文件（即使逻辑简单）。  

---

#### **EMIO硬件配置（FPGA工程师任务）**  
1. **Vivado工程配置**：  
   - 复制“ps_hello”工程为“ps_emio”，打开ZYNQ核配置。  
   - 勾选 **GPIO EMIO**，设置EMIO位宽为8（对应4个LED + 1个按键）。  
   - 导出EMIO信号：右键`GPIO_0`端口，选择 **Make External**。  

2. **PL引脚约束**：  
   - 在XDC文件中绑定EMIO信号至PL端物理引脚（需参考开发板原理图）：  
     ```tcl  
     set_property PACKAGE_PIN <引脚编号> [get_ports {GPIO_0_tri_io[0]}]  # LED0  
     set_property PACKAGE_PIN <引脚编号> [get_ports {GPIO_0_tri_io[4]}]  # 按键  
     ```  

---

#### **SDK软件开发（软件工程师任务）**  

##### **9.4.1 EMIO点亮PL端LED灯**  
1. **工程创建**：  
   - 新建SDK工程“emio_led_test”，模板选择“Hello World”。  

2. **代码修改**：  
   - 修改LED引脚编号为EMIO起始值（54~61，对应GPIO_0的8位信号）：  
     ```c  
     #define LED_PIN 54  // PL端LED0对应EMIO54  
     XGpio_DiscreteWrite(&Gpio, 1, LED_PIN, 0x1); // 点亮LED  
     ```  

##### **9.4.2 EMIO实现PL端按键中断**  
1. **工程创建**：  
   - 新建工程“emio_key_test”，移植MIO按键中断代码。  

2. **关键修改**：  
   - 按键和LED引脚编号调整（例如按键EMIO58，LED EMIO54）：  
     ```c  
     #define KEY_PIN 58  // PL按键对应EMIO58  
     #define LED_PIN 54  // PL LED对应EMIO54  
     ```  
   - 中断配置：  
     ```c  
     // 设置按键为上升沿触发  
     XGpio_InterruptEnable(&Gpio, 1 << KEY_PIN);  
     XGpio_InterruptGlobalEnable(&Gpio);  
     ```  

3. **中断服务程序**：  
   ```c  
   void GpioHandler(void) {  
       if (XGpio_InterruptGetStatus(&Gpio)) {  
           XGpio_InterruptClear(&Gpio, 1 << KEY_PIN);  
           XGpio_DiscreteWrite(&Gpio, 1, LED_PIN, ~LED_STATE); // 翻转LED状态  
       }  
   }  
   ```  

---

#### **固化程序生成**  
1. **生成启动镜像**：  
   - 创建FSBL工程（勾选调试信息）。  
   - 右键APP工程，选择 **Create Boot Image**，包含：  
     - FSBL.elf  
     - design_1_wrapper.bit（PL配置比特流）  
     - emio_led_test.elf（应用程序）  

2. **烧录至SD卡**：  
   - 将生成的`BOOT.bin`文件拷贝至SD卡FAT32分区，开发板启动模式设为SD卡。  

---

#### **注意事项**  
1. **EMIO与PL引脚映射**：  
   - EMIO信号需通过XDC文件绑定至PL物理引脚，否则无法生效。  
   - 即使无复杂PL逻辑，仍需生成比特流文件以配置引脚连接。  

2. **中断优先级配置**：  
   - 操作`ICDIPR`（优先级）和`ICDICFR`（触发方式）寄存器，确保中断控制器正确响应。  

3. **代码兼容性**：  
   - 不同开发板的EMIO引脚编号可能不同，需根据原理图调整代码中的宏定义。  

---

#### **实验总结**  
通过本实验可掌握：  
- **EMIO配置流程**：从Vivado硬件配置到PL引脚约束。  
- **PS-PL交互方法**：通过EMIO控制PL外设，实现GPIO输出与中断输入。  
- **固化程序生成**：集成FSBL、比特流与应用程序，完成系统级部署。  

EMIO为PS与PL协同设计的基础，后续可扩展至复杂外设（如自定义IP核）控制。