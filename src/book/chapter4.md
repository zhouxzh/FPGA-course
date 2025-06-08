---
title: "第4讲：FPGA数字接口设计"
author: [周贤中]
date: 2025-03-30
subject: "Markdown"
keywords: [FPGA, 系统设计]
lang: "zh-cn"
...
---

**数字系统**通过其模拟和数字接口与外部世界通信。本章重点探讨现场可编程门阵列（FPGA）设计中的数字接口技术。我们将首先介绍串行通信协议，包括通用异步收发器（UART）、串行外设接口（SPI）和内部集成电路（I²C）。随后，我们将讨论通用串行总线（USB）和以太网连接。除以太网外，我们将为所有数字接口概念提供Verilog描述。为清晰阐述数字接口概念，本章还提供了相关应用实例。

## 通用异步收发器

通用异步收发器（UART）是一种用于两个或多个设备之间的数字通信协议。我们仅关注两个设备之间的UART通信。因此，一个设备作为发送器，另一个作为接收器。通信通过发送器和接收器之间的异步数据传输完成。由于是异步通信，UART不需要发送器和接收器之间的共同时钟，因此连接的设备可以独立工作。发送器的串行引脚通常称为发送（TX），对应的接收器引脚称为接收（RX）。发送器和接收器之间通过物理连接这两个引脚建立通信链路。

UART通信可以在不同设备之间建立。我们将特别关注目标FPGA开发板与PC之间的通信。为此，我们将开发发送器和接收器模块的硬件描述语言（HDL）实现。发送器模块本质上是一个移位寄存器，它加载并行数据并以特定速率通过设备的TX引脚逐位移出。接收器模块将通过RX引脚接收的串行数据转换为并行格式，供接收器处理。在深入HDL描述之前，让我们先了解UART的工作原理。

### UART工作原理

要使用UART，我们需要理解其工作机制。因此，本节将介绍数据格式、时序、发送和接收操作。这些内容将帮助我们在下一节构建HDL描述。

#### 数据格式

UART以数据包的形式传输数据。一个UART数据包的帧结构以起始位开始，后跟7到8个数据位，最后以一个或两个停止位结束。这种配置如图所示。
![uart](img4/UART.jpeg)

#### 时序

尽管UART以异步方式工作，但发送器和接收器必须具有相同的时序参数才能正确收发数据。换句话说，数据可以异步传输，但一旦传输开始，接收器必须知道UART数据包中每个脉冲的持续时间。这由波特率决定，它定义了时序。波特率的单位为比特每秒（bps）。例如，2400 bps表示UART传输中每个比特的宽度（或周期）为416微秒。

#### 发送操作

我们可以将UART的发送操作描述为一个状态机。我们将在后续章节详细解释这个状态机。这里先简要概述：当发送器处于空闲模式时，TX引脚应保持逻辑电平1。一旦传输开始，数据发送线上会产生一个下降沿，唤醒接收器。随后，时钟根据波特率设置，发送器在每个时钟周期逐位发送所有数据。接收器必须具有相同的波特率才能顺序接收传输的比特。当发送操作完成时，TX引脚应设置为逻辑电平1并保持一个或两个比特宽度，以通知接收器传输结束。这部分称为停止位。停止位的数量和奇偶校验位的使用也应预先确定，以确保发送器和接收器具有相同的设置。

#### 接收操作

我们可以将UART的接收操作描述为另一个状态机。接收器最初处于就绪状态。当RX引脚检测到下降沿信号（起始位）时，它开始顺序接收数据位。为此，接收器必须像发送器一样具有一个基于预定波特率的内部定时器。接收到起始位后，定时器等待一定时间以采样第一个数据位。这个偏移允许在第一个数据脉冲的中间位置开始采样过程。请注意，尽管数据由发送器以逻辑电平1和0发送，但这些信号会转换为模拟脉冲信号。因此，采样操作将接收到的模拟信号重新转换为逻辑电平0或1。随后，我们在每个连续的时间段执行采样操作以恢复数据位。当所有比特都以这种方式接收后，接收器检查接收数据中的奇偶校验位（如果协议包含）。当接收到停止位时，接收器返回到就绪状态，等待接收下一个数据包。


我们可以将发送和接收操作描述为Verilog中的两个独立模块。让我们从发送器模块开始。

### 发送器模块的verilog实现

```verilog
`timescale 1ns / 1ps

module uart_tx (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire tx_start,      // Start transmission signal
    input wire [7:0] tx_data, // Data to transmit
    output reg tx_done,       // Transmission complete signal
    output reg tx             // Serial output
);

    // Parameters for UART configuration
    parameter CLK_FREQ = 50000000;  // 50MHz system clock
    parameter BAUD_RATE = 115200;   // Baud rate
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    // Internal registers
    reg [1:0] state;
    reg [1:0] next_state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_data_reg;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_data_reg <= 0;
            tx <= 1'b1;  // Idle state is high
            tx_done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;  // Idle state is high
                    tx_done <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        state <= START;
                    end
                end
                
                START: begin
                    tx <= 1'b0;  // Start bit is low
                    
                    // Wait for one bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    tx <= tx_data_reg[bit_index];
                    
                    // Wait for one bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        // Check if we have sent all bits
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;  // Stop bit is high
                    
                    // Wait for one bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        tx_done <= 1'b1;
                        clk_count <= 0;
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
```
---

#### **模块功能概述**
该模块实现了一个UART发送控制器，将8位并行数据转换为符合UART协议的串行数据流。关键功能包括：
- **异步复位**（低电平有效）
- **波特率可配置**（基于系统时钟频率和波特率参数）
- **状态机控制**：处理空闲、起始位、数据位、停止位状态
- **完成信号输出**（`tx_done`）

---

#### **端口定义**
```verilog
module uart_tx (
    input wire clk,           // 系统时钟（50MHz）
    input wire rst_n,         // 低电平复位
    input wire tx_start,      // 发送启动信号（上升沿触发）
    input wire [7:0] tx_data, // 待发送的8位数据
    output reg tx_done,       // 发送完成标志（单周期脉冲）
    output reg tx             // 串行输出引脚
);
```

---

#### **参数配置**
- **`CLK_FREQ`**：系统时钟频率（默认50MHz）
- **`BAUD_RATE`**：波特率（默认115200）
- **`CLKS_PER_BIT`**：每个UART位所需的时钟周期数  
  计算公式：  
  ```verilog
  CLKS_PER_BIT = CLK_FREQ / BAUD_RATE  // 例：50M/115200 ≈ 434
  ```

---

#### **状态机设计**
使用四状态有限状态机（FSM）控制发送流程：

| 状态    | 描述               | 输出（`tx`） | 持续时间           |
|---------|--------------------|--------------|--------------------|
| **IDLE**  | 空闲状态           | 高电平       | 等待`tx_start`信号 |
| **START** | 发送起始位         | 低电平       | 1个位周期          |
| **DATA**  | 发送8位数据（LSB优先）| 数据位       | 8个位周期          |
| **STOP**  | 发送停止位         | 高电平       | 1个位周期          |

---

#### **关键逻辑解析**
##### **1. 复位逻辑**
- 复位时所有寄存器和输出初始化：
  ```verilog
  state <= IDLE;        // 回到空闲状态
  clk_count <= 0;       // 计数器清零
  bit_index <= 0;       // 数据位索引复位
  tx <= 1'b1;           // 保持空闲高电平
  tx_done <= 1'b0;      // 完成信号置低
  ```

##### **2. 状态转移逻辑**
- **IDLE → START**：  
  检测到`tx_start`信号后，锁存数据到`tx_data_reg`，进入起始位状态。
- **START → DATA**：  
  起始位持续`CLKS_PER_BIT`周期后进入数据发送。
- **DATA → STOP**：  
  按`bit_index`顺序发送8位数据（LSB优先），完成后进入停止位。
- **STOP → IDLE**：  
  停止位持续完成后，拉高`tx_done`并返回空闲。

##### **3. 数据发送细节**
- **LSB优先**：  
  `bit_index`从0递增到7，依次发送`tx_data_reg[0]`到`tx_data_reg[7]`。
- **位定时**：  
  每个状态通过`clk_count`计数器确保精确的位周期（`CLKS_PER_BIT`）。

##### **4. 完成信号生成**
- **`tx_done`**：  
  在停止位状态的最后一个时钟周期置高，持续一个时钟周期。

---

#### **关键设计要点**
1. **波特率精度**  
   通过整数除法计算`CLKS_PER_BIT`，可能引入微小误差（例如50MHz/115200≈434），需确保误差在可接受范围内（通常<3%）。

2. **数据锁存**  
   `tx_data`在`tx_start`有效时被锁存到`tx_data_reg`，确保发送过程中数据稳定。

3. **抗干扰设计**  
   - 仅在`IDLE`状态响应`tx_start`，防止发送过程中被意外打断。
   - 状态机包含`default`分支，增强鲁棒性。

4. **时序对齐**  
   每个状态的计数器从0到`CLKS_PER_BIT-1`，确保精确的位周期（如434周期对应115200波特率）。

---

#### **潜在改进点**
- **校验位支持**：可扩展状态机添加奇偶校验位。
- **可配置帧格式**：通过参数支持不同数据位宽（如7/9位）或停止位数。
- **双缓冲机制**：添加数据缓冲区，允许在发送过程中预加载下一帧数据。

---

#### **仿真测试建议**
1. **复位测试**：验证复位后所有信号是否初始化为预期值。
2. **单字节发送**：检查起始位、数据位、停止位的时序和电平。
3. **连续发送**：验证`tx_done`脉冲能否正确触发下一次发送。
4. **波特率验证**：测量实际位周期是否匹配理论值。

---

该模块完整实现了UART发送功能的核心逻辑，代码结构清晰，适合作为嵌入式系统或FPGA设计中的串行通信接口。

---
#### 发送器测试模块

```verilog
`timescale 1ns / 1ps

module uart_rx_tb;

// Parameters
parameter CLK_PERIOD = 20;    // 50MHz clock (20ns period)
parameter BAUD_RATE = 115200;
parameter BIT_PERIOD = 1000000000 / BAUD_RATE;  // Bit period in ns

// DUT Signals
reg clk;
reg rst_n;
reg rx;
wire [7:0] rx_data;
wire rx_ready;

// Instantiate DUT
uart_rx #(
    .CLK_FREQ(50000000),  // 50MHz
    .BAUD_RATE(BAUD_RATE)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .rx_data(rx_data),
    .rx_ready(rx_ready)
);

// Clock generation
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Test sequence
initial begin
    // Initialize signals
    rst_n = 0;
    rx = 1;
    
    // Reset sequence
    #100;
    rst_n = 1;
    #100;
    
    // Test case 1: Send 0x55 (01010101)
    send_byte(8'h55);
    #(BIT_PERIOD*3);
    
    // Verify reception
    if(rx_data !== 8'h55 || rx_ready !== 1'b1)
        $error("Test 1 failed: Received 0x%h", rx_data);
        
    // Test case 2: Send 0xAA (10101010)  
    send_byte(8'hAA);
    #(BIT_PERIOD*3);
    
    if(rx_data !== 8'hAA || rx_ready !== 1'b1)
        $error("Test 2 failed: Received 0x%h", rx_data);
    
    // End simulation
    $display("All tests completed");
    $finish;
end

// UART byte transmission task
task send_byte;
    input [7:0] data;
    integer i;
    begin
        // Start bit
        rx = 0;
        #BIT_PERIOD;
        
        // Data bits (LSB first)
        for(i=0; i<8; i=i+1) begin
            rx = data[i];
            #BIT_PERIOD;
        end
        
        // Stop bit
        rx = 1;
        #BIT_PERIOD;
    end
endtask

// Monitor signals
initial begin
    $monitor("Time: %t, RX: %b, Data: 0x%h, Ready: %b",
            $time, rx, rx_data, rx_ready);
end

// Generate VCD file
initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_tb);
end

endmodule
```
#### 仿真结果
![tx](img4/tx.png)


### 接收器模块的verilog实现

```verilog
`timescale 1ns / 1ps

module uart_rx (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire rx,            // Serial input
    output reg rx_ready,      // Data ready signal
    output reg [7:0] rx_data  // Received data
);

    // Parameters for UART configuration
    parameter CLK_FREQ = 50000000;  // 50MHz system clock
    parameter BAUD_RATE = 115200;   // Baud rate
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // State machine states
    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam DATA = 3'b010;
    localparam STOP = 3'b011;
    localparam CLEANUP = 3'b100;
    
    // Internal registers
    reg [2:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] rx_data_reg;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_data_reg <= 0;
            rx_ready <= 1'b0;
            rx_data <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    rx_ready <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    // Detect start bit (falling edge on rx)
                    if (rx == 1'b0) begin
                        state <= START;
                    end
                end
                
                START: begin
                    // Wait for middle of start bit
                    if (clk_count < (CLKS_PER_BIT - 1) / 2) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        // Check if start bit is still low
                        if (rx == 1'b0) begin
                            // Reset counter for data bits
                            clk_count <= 0;
                            state <= DATA;
                        end else begin
                            // False start, go back to idle
                            state <= IDLE;
                        end
                    end
                end
                
                DATA: begin
                    // Wait for middle of data bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        // Sample the data bit
                        rx_data_reg[bit_index] <= rx;
                        
                        // Check if we have received all bits
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    // Wait for middle of stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        // Check if stop bit is high
                        if (rx == 1'b1) begin
                            rx_ready <= 1'b1;
                            rx_data <= rx_data_reg;
                        end
                        
                        clk_count <= 0;
                        state <= CLEANUP;
                    end
                end
                
                CLEANUP: begin
                    // Wait one clock cycle to clear rx_ready
                    state <= IDLE;
                    rx_ready <= 1'b0;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
```

---

#### **模块概述**
该模块实现了一个UART接收器，负责从串行输入`rx`中异步接收数据，并将接收到的8位数据通过`rx_data`输出，同时用`rx_ready`信号指示数据就绪。

---

### **关键参数与信号**
1. **参数配置**
   - `CLK_FREQ`：系统时钟频率（50MHz）。
   - `BAUD_RATE`：波特率（115200）。
   - `CLKS_PER_BIT`：每个UART位占用的时钟周期数，计算为`CLK_FREQ / BAUD_RATE`（约为434）。

2. **状态定义**
   - `IDLE`：空闲状态，等待起始位。
   - `START`：检测起始位有效性。
   - `DATA`：接收8位数据。
   - `STOP`：验证停止位。
   - `CLEANUP`：清理状态，复位信号。

3. **内部寄存器**
   - `state`：状态机当前状态。
   - `clk_count`：位周期计数器。
   - `bit_index`：当前接收的数据位索引（0-7）。
   - `rx_data_reg`：临时存储接收的数据。

---

#### **状态机详细流程**
##### **1. IDLE状态**
- **行为**：
  - 复位`rx_ready`、`clk_count`、`bit_index`。
  - 检测起始位：当`rx`出现下降沿（低电平），进入`START`状态。
- **关键点**：
  - 未进行多次采样，可能受噪声干扰产生误触发。

##### **2. START状态**
- **行为**：
  - 计数至起始位中点（`(CLKS_PER_BIT-1)/2`）。
  - 在中点检查`rx`是否仍为低电平：
    - 是：进入`DATA`状态，开始接收数据。
    - 否：回到`IDLE`，视为虚假起始位。
- **关键点**：
  - 中点采样确保起始位有效性，减少误判。

##### **3. DATA状态**
- **行为**：
  - 计数满一个位周期（`CLKS_PER_BIT`）。
  - 在周期结束时（非中点）采样`rx`，存入`rx_data_reg`。
  - 接收完8位后进入`STOP`状态。
- **关键问题**：
  - **采样点错误**：数据位采样发生在位周期末尾而非中点，易受信号跳变影响，可能导致数据错误。

##### **4. STOP状态**
- **行为**：
  - 计数满一个位周期。
  - 在周期结束时检查`rx`是否为高电平：
    - 是：将`rx_data_reg`输出至`rx_data`，并置位`rx_ready`。
    - 否：未处理帧错误，直接进入清理状态。
- **关键点**：
  - 停止位检查在末尾，而非中点，可能无法有效验证停止位完整性。

##### **5. CLEANUP状态**
- **行为**：
  - 复位`rx_ready`，回到`IDLE`状态。
- **作用**：
  - 确保`rx_ready`仅持续一个时钟周期，避免重复读取。

---

#### **潜在问题与改进**
1. **数据位采样点错误**
   - **问题**：当前在数据位末尾采样，易受信号跳变影响。
   - **改进**：在数据位中点（`CLKS_PER_BIT/2`）采样，提高稳定性。
   - **修改示例**：
     ```verilog
     DATA: begin
         if (clk_count < CLKS_PER_BIT - 1) begin
             clk_count <= clk_count + 1;
             // 在中点采样
             if (clk_count == (CLKS_PER_BIT/2 - 1)) begin
                 rx_data_reg[bit_index] <= rx;
                 bit_index <= bit_index + 1;
             end
         end else begin
             clk_count <= 0;
             if (bit_index >= 7) state <= STOP;
         end
     end
     ```

2. **停止位验证不足**
   - **问题**：未在中点检查停止位，可能接收不完整帧。
   - **改进**：在中点验证停止位，若无效则丢弃数据。

3. **无帧错误处理**
   - **问题**：未检测停止位错误，错误数据仍被输出。
   - **改进**：添加帧错误标志（如`rx_error`），供外部处理。

---

- **功能**：代码实现了基本的UART接收功能，但存在采样点错误和验证不严谨的问题。
- **改进方向**：调整数据位采样点为中点，增强停止位检查，添加错误处理逻辑。
- **应用场景**：适用于对稳定性要求不高的场景，需谨慎用于高噪声或精确通信环境。

#### 测试模块

```verilog
`timescale 1ns / 1ps

module uart_rx_tb;

// Parameters
parameter CLK_PERIOD = 20;    // 50MHz clock (20ns period)
parameter BAUD_RATE = 115200;
parameter BIT_PERIOD = 1000000000 / BAUD_RATE;  // Bit period in ns

// DUT Signals
reg clk;
reg rst_n;
reg rx;
wire [7:0] rx_data;
wire rx_ready;

// Instantiate DUT
uart_rx #(
    .CLK_FREQ(50000000),  // 50MHz
    .BAUD_RATE(BAUD_RATE)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .rx_data(rx_data),
    .rx_ready(rx_ready)
);

// Clock generation
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Test sequence
initial begin
    // Initialize signals
    rst_n = 0;
    rx = 1;
    
    // Reset sequence
    #100;
    rst_n = 1;
    #100;
    
    // Test case 1: Send 0x55 (01010101)
    send_byte(8'h55);
    #(BIT_PERIOD*3);
    
    // Verify reception
    if(rx_data !== 8'h55 || rx_ready !== 1'b1)
        $error("Test 1 failed: Received 0x%h", rx_data);
        
    // Test case 2: Send 0xAA (10101010)  
    send_byte(8'hAA);
    #(BIT_PERIOD*3);
    
    if(rx_data !== 8'hAA || rx_ready !== 1'b1)
        $error("Test 2 failed: Received 0x%h", rx_data);
    
    // End simulation
    $display("All tests completed");
    $finish;
end

// UART byte transmission task
task send_byte;
    input [7:0] data;
    integer i;
    begin
        // Start bit
        rx = 0;
        #BIT_PERIOD;
        
        // Data bits (LSB first)
        for(i=0; i<8; i=i+1) begin
            rx = data[i];
            #BIT_PERIOD;
        end
        
        // Stop bit
        rx = 1;
        #BIT_PERIOD;
    end
endtask

// Monitor signals
initial begin
    $monitor("Time: %t, RX: %b, Data: 0x%h, Ready: %b",
            $time, rx, rx_data, rx_ready);
end

// Generate VCD file
initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_tb);
end

endmodule
```

---

#### 仿真结果

![rx](img4/rx.png)

---

### 联合发送器模块与接收器模块的仿真结果

#### 测试模块代码

```verilog
`timescale 1ns / 1ps

module uart_tb;

    // Parameters
    parameter CLK_PERIOD = 20;    // 50MHz clock (20ns period)
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = 1000000000 / BAUD_RATE;  // Bit period in ns
    
    // Testbench signals
    reg clk;
    reg rst_n;
    wire rx;
    wire rx_ready;
    wire [7:0] rx_data;
    
    // Test control signals
    reg [7:0] test_data;
    reg tx_start;
    wire tx_done;
    
    // Instantiate UART transmitter (to generate test signals)
    uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(test_data),
        .tx_done(tx_done),
        .tx(rx)  // Connect TX output to RX input
    );
    
    // Instantiate UART receiver
    uart_rx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        tx_start = 0;
        test_data = 8'h00;
        
        // Apply reset
        #100;
        rst_n = 1;
        #100;
        
        // Test case 1: Send character 'A' (0x41)
        test_data = 8'h41;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Verify received data
        if (rx_data !== 8'h41 || rx_ready !== 1'b1) 
            $error("Test 1 Failed: Received 0x%h, Expected 0x41", rx_data);
        
        // Test case 2: Send character 'Z' (0x5A)
        test_data = 8'h5A;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Verify received data
        if (rx_data !== 8'h5A || rx_ready !== 1'b1) 
            $error("Test 2 Failed: Received 0x%h, Expected 0x5A", rx_data);
        
        // Test case 3: Send random data
        test_data = 8'hA5;
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        @(posedge tx_done);
        #(BIT_PERIOD * 2);
        
        // Verify received data
        if (rx_data !== 8'hA5 || rx_ready !== 1'b1) 
            $error("Test 3 Failed: Received 0x%h, Expected 0xA5", rx_data);
        
        // End simulation
        $display("All tests completed successfully");
        $finish;
    end
    
    // Monitor signals
    initial begin
        $monitor("Time: %t, RX: %b, Data: 0x%h, Ready: %b",
                $time, rx, rx_data, rx_ready);
    end
    
    // Generate VCD file for waveform viewing
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule
```

#### 仿真结果

![uart_tb](img4/uart_tb.png)


### **SPI工作原理**

SPI（串行外设接口）的工作机制比UART更为简洁。为深入理解其原理，本节将重点解析四大核心要素：

1. **数据格式**  
   SPI采用全双工同步传输，数据帧通常为8位或16位，支持MSB（高位优先）或LSB（低位优先）传输模式。时钟极性（CPOL）与时钟相位（CPHA）的组合形成四种工作时序模式。

2. **连接拓扑**  
   典型SPI系统包含以下信号线：
   - SCLK：主设备提供的同步时钟
   - MOSI：主设备输出/从设备输入
   - MISO：主设备输入/从设备输出  
   - SS：从设备选择线（低电平有效）

3. **传输机制**  
   主设备通过拉低SS信号选择从设备后：
   - 主设备在SCLK边沿（由CPHA决定）通过MOSI发送数据
   - 从设备同步通过MISO返回数据
   - 每个时钟周期完成1位数据的双向传输

4. **时序特性**  
   - 时钟频率可达数十MHz（远高于UART）
   - 数据有效性由CPOL/CPHA决定：
     * CPOL=0时，SCLK空闲为低电平
     * CPHA=0时，数据在时钟第一个边沿采样

#### **SPI数据格式**  

与UART不同，SPI的数据包长度可自由配置，这一特性赋予用户极大的灵活性。由于采用专用时钟线和使能信号，SPI无需UART的起止位，仅需通信双方预先约定数据包长度即可实现可靠传输。

#### **SPI连接拓扑**  

SPI采用四线制连接（如图所示）：
- **SCK**：同步时钟（主设备产生）
- **MOSI**：主设备输出/从设备输入
- **MISO**：主设备输入/从设备输出  
- **SS**：从设备选择信号（低有效）

![SPI主从设备连接示意图](img4/SPI.jpeg)  


#### **SPI传输机制**  

主设备通过SCK和SS信号控制通信流程：

1. 空闲状态下SS为高电平，SCK电平由SPI模式决定
2. 主设备拉低SS信号激活从设备
3. 每个SCK周期完成1位数据的双向传输（MOSI发送/MISO接收）
4. 传输结束后SS恢复高电平

#### **SPI时序模式**  

通过CPOL（时钟极性）和CPHA（时钟相位）可组合出四种工作模式：

| 模式 | CPOL | CPHA | 时钟特性                  | 数据采样边沿       |
|------|-------|-------|---------------------------|--------------------|
| 0    | 0     | 0     | 空闲低电平，上升沿有效    | 时钟上升沿采样     |
| 1    | 0     | 1     | 空闲低电平，下降沿有效    | 时钟下降沿采样     |
| 2    | 1     | 0     | 空闲高电平，下降沿有效    | 时钟下降沿采样     |
| 3    | 1     | 1     | 空闲高电平，上升沿有效    | 时钟上升沿采样     |

![图12.3 SPI时序图](img4/SPI2.jpeg)  

### **Verilog实现方案**  

#### **主设备发送模块**  

代码清单展示了主设备发送模块的Verilog实现：  

- **输入端口**：clk（系统时钟）、data（待发送数据）、send（发送触发）  
- **输出端口**：sck（SPI时钟）、mosi（主出从入）、ss（片选）、busy（忙标志）  
- **关键参数**：可配置数据包长度，默认2MHz时钟频率，CPOL=CPHA=0  

**状态机工作流程**：  

1. **RDY状态**：等待send触发信号  
2. **START状态**：拉低SS，加载首比特数据  
3. **TRANSMIT状态**：逐位发送数据  
4. **STOP状态**：释放SS，返回就绪状态  

```Verilog Description of the SPI Follower-Transmitter Module
module SPI_leader_transmitter(clk,data,send,sck,ss,mosi,busy);
parameter data length=8;
input clk;
input [data length-1:0] data;
input send;
output reg sck=0;
output reg ss=1;
output reg mosi;
output reg busy=0;
localparam RDY=2'b00, START=2'b01, TRANSMIT=2'b10, STOP=2'b11;
reg [1:0] state=RDY;
reg [7:0] clkdiv=0;
reg [7:0] index=0;
always @ (posedge clk)
//sck is set to 2 MHz
if (clkdiv == 8'd24)
       begin
   clkdiv <= 0;
      sck <= ~sck;
        end
else clkdiv <= clkdiv + 1;
always @ (negedge sck)
case (state)
RDY:
       if (send)
       begin
       state <= START;
       busy <= 1;
      index <= data_length-1;
       end
START :
       begin
        SS <= 0;
      mosi <= data[index];
      index <= index - 1;
        state <= TRANSMIT;
        end
TRANSMIT:
       begin
if (index == 0)
       state <= STOP;
        mosi <= data[index] ;
        index <= index - 1;
       end
STOP:
       begin
       busy <= 0;
        SS <= 1;
      state <= RDY;
        end
endcase
endmodule
```

以下是跟随器-发射器模块的Verilog描述。作为跟随模块，其输入信号为sck、ss和data，输出信号为miso和busy。时序模式CPOL和CPHA设置为0，因此所有状态变化都发生在sck的下降沿。
该模块（作为状态机）的工作原理与领导者-发射器模块类似，主要区别如下：状态机初始处于RDY状态，由领导者-接收器产生的sck下降沿触发。当ss为逻辑0电平时，busy变为逻辑1电平。数据向量的首bit被加载到mosi，随后状态机进入TRANSMIT状态开始传输数据。当index归零时，所有数据位已发送完毕，状态机转入STOP状态（复位index并置busy为0），随后返回RDY状态等待ss信号的下次触发。

#### 12.2.2.2 接收器模块

接收端同样分为领导者和跟随者两种模式：

1. 跟随方接收模块
输入sck/ss/mosi，输出data/busy/ready。
核心特征：

- `busy=1`表示数据接收中
- `ready=1`时有效数据在data总线就绪
- 数据长度通过参数可配置

工作原理：

- 初始化`data_temp=0`，`index=data_length-1`
- 状态机RDY→RECEIVE→STOP循环：
  - RDY状态在每个sck上升沿检测ss=0
  - 接收到起始信号后加载首bit，`busy=1`，`ready=0`
  - RECEIVE状态形如移位寄存器逐bit接收
  - index归零时置位ready并回写data总线
  - 需与领导者-发射器模块协同工作

1. 领导方接收模块
输入clk/miso/get信号，输出data/sck/ss/busy/ready。核心特征：

- 主时钟分频输出2MHz的sck
- `get=1`触发接收流程
- 接收完成时`ready=1`

工作原理：
- 状态机RDY→RECEIVE→STOP循环：
  - RDY状态等待get信号触发
  - RECEIVE阶段`ss=0`启动SPI会话
  - 每个sck上升沿接收数据位
  - index归零后写data总线，`ready=1`
  - 需与跟随器-发射器模块协同工作

```Verilog
module SPI_follower_receiver (sck,ss, mosi, data, busy, ready) ;
parameter data length=8;
input sck;
input ss;
input mosi;
output reg [data length-1:0] data;
output reg busy=0;
output reg ready=0;
localparam RDY=2'b00, RECEIVE=2'b01, STOP=2'b10;
reg [1:0] state=RDY;
reg [data length-1:0] data temp=0;
reg [7:0] index=data length-1;
always @ (posedge sck)
case (state)
RDY :
        if (!ss)
      begin
       data temp[index] <= mosi;
        index <= index - 1;
       busy <= 1;
        ready <= 0;
       state <= RECEIVE;
        end
RECEIVE:
        begin
        if (index == 0)
        state <= STOP;
        else index <= index - 1;
        data temp[index] <= mosi;
        end
STOP :
        begin
        busy <= 0;
        ready <= 1;
        data temp <= 0;
        data <= data temp;
        index <= data length-1;
        state <= RDY;
        end
endcase
endmodule
```

```Verilog
module SPI_leader_receiver (clk, miso, get, data, sck, ss, busy, ready) ;
parameter data length=8;
input clk;
input miso;
input get;
output reg [data length-1:0] data;
output reg sck=0;
output reg ss=1;
output reg busy=0;
output reg ready=0;
localparam RDY=2'b00, RECEIVE=2'b01, STOP=2'b10;
reg [1:0] state=RDY;
reg [data_length-1:0] data_temp=0;
reg [7:0] clkdiv=0;
reg [7:0] index=0;
always @ (posedge clk)
//sck is set to 2 MHz
if (clkdiv == 8'd24)
       begin
       clkdiv <= 0;
       sck <= ~sck ;
        end
else
  clkdiv <= clkdiv + 1;
always @ (posedge sck)
case (state)
RDY:                           
       begin
       SS <= 0;
       state <= RECEIVE;
       busy <= 1;
       ready <= 0;
       data temp <= 0;
       index <= data_length-1; 
         end
RECEIVE:
         begin
         if (index == 0) state <= STOP;
         data temp[index] <= miso;
         index <= index - 1;
         end
STOP:
         begin
         busy <= 0;
         ready <= 1;
        SS <= 1;
         data <= data temp;
       state <= RDY;
        end
endcase
endmodule
```

#### I²C 总线工作原理

I²C 是支持多主多从架构的数字设备间串行通信协议，本书主要探讨双设备通信场景。本节将从数据格式、连接原理图和收发机制三方面解析其工作原理。

### 数据格式*I²C 协议核心特征：

- 每个从设备持有唯一地址（通常7bit，可扩展至8/10bit）
- 通信起始于主设备发送从机地址
- 数据以8bit为单元传输，每单元包含：
  * 7bit地址/指针/数据 
  * 1bit应答位（ACK）
- 接收端通过组合多单元数据包解析信息

### 连接原理

标准I²C系统构成：

- 双线制总线：
  - 串行数据线（SDA）
  - 串行时钟线（SCL）
--共需四线连接：
  - SDA/SCL总线
  - 共地线（GND） 
  - 供电线（VDD）
- 关键电路特性：
  - SDA/SCL均通过上拉电阻接VDD
  - 总线闲置时保持逻辑1电平

![I2C](img4/I2C.jpeg)

#### **12.3.2 Verilog中的I2C实现**

我们提供了I2C主控模块的Verilog描述。该模块包含六个输入信号：clk、reset_n、ena、addr、rw和data_wr。其中，clk对应模块使用的时钟信号；reset_n表示低电平有效的复位信号；ena为高电平有效的使能信号；addr表示待连接从设备的地址；rw为读/写控制输入——当该信号为逻辑1时模块执行读操作，否则执行写操作。

模块设有四个输出信号：busy、data_rd、ack_error和eop。当模块正在传输或接收数据时，busy将保持逻辑1电平；data_rd显示从从设备读取的数据；ack_error表示高电平有效的应答错误标志；eop指示数据包传输结束。此外，模块还包含双向信号sda和scl，分别对应I2C的串行数据和串行时钟信号。

```Verilog 
module I2C_leader (clk, reset n, ena, addr, rw, data wr, busy, data rd,
    ack error,eop,sda,scl);
input clk;
input reset n;
input ena;
input [6:0] addr;
input rw;
input [7:0] data wr;
output reg busy ;
output reg [7:0] data rd;
output reg ack error;
output reg eop=0;
inout sda;
inout scl;
parameter input clk=1000000000;
parameter bus clk=400000;
localparam READY=4'b000, START=4'b0001, COMMAND=4'b0010, SLV ACK1=4'
    b0011, WR=4'b0100, RD=4'b0101, SLV ACK2=4'b0110, MSTR ACK=4'b0111,
    STOP=4'b1000;
reg [3:0] state;
integer divider=(input clk/bus clk) /4;
reg data clk;
reg data clk prev;
reg scl clk;
reg scl ena=0;
reg sda int=1;
reg sda ena n;
reg [7:0] addr rw;
reg [7:0] data tx;
reg [7:0] data rx;
reg [2:0] bit cnt=3'd7;
reg [31:0] count;
always @ (posedge clk, negedge reset n)
begin
if (reset n == 0)
count <= 0;
else
begin
data clk prev <= data clk;
if(count == divider*4-1) count <= 0;
else
begin
count <= count + 1;
if (count >= 0 && count < divider-1)
begin
scl clk <= 0;
data clk <= 0; end
```

```Verilog
else if (count >= divider && count < divider*2-1)
begin
scl clk <= 0;
data clk <= 1; end
else if (count >= divider*2 && count < divider*3-1)
begin
scl clk <= 1;
data clk <= 1;
end
else if (count >= divider*3 && count < divider*4-1) begin
scl clk <= 1;
data clk <= 0;
end
else begin
scl_clk <= scl_clk;
data clk <= data clk;
end
end
end
end
always @ (posedge clk, negedge reset n)
begin
if (reset n == 0)
begin
state <= READY;
busy <= 1;
scl ena <= 0;
sda int <= 1;
ack error <= 0;
bit cnt <= 3'd7;
data rd <= 8'b0;
end
else
begin
if (data clk == 1 && data clk prev == 0)
case (state)
READY:
 if (ena == 1)
       begin
       busy <= 1;
       addr_rw <= {addr,rw};
      data tx <= data wr;
       state <= START;
        end
        else
       begin
       busy <= 0;
       state <= READY;
        end
START:
       begin
       busy <= 1;
        sda int <= addr rw[bit cnt];
```

```Verilog
state <= COMMAND;
        end
COMMAND :
        if (bit cnt == 0)
        begin
        sda int <= 1;
        bit cnt <= 3'd7;
        state <= SLV ACK1;
        end
        else begin
        bit cnt <= bit cnt - 1;
        sda int <= addr rw[bit cnt-1] ;
        state <= COMMAND;
        end
SLV ACK1:
        if (addr rw[0] == 0)
        begin
        sda int <= data tx[bit cnt];
        state <= WR;
        end
        else
        begin
        sda int <= 1;
        state <= RD;
        end
WR :
        begin
        busy <= 1;
        if (bit cnt == 0)
        begin
        sda int <= 1;
        bit cnt <= 3'd7;
        state <= SLV ACK2;
        end
        else if (bit cnt == 1)
        begin
        bit cnt <= bit cnt - 1;
        sda_int <= data_tx[bit_cnt-1];
        eop <= 1;
        end
        else begin
        bit cnt <= bit cnt - 1;
        sda int <= data tx [bit cnt-1] ;
        state <= WR;
        end
        end
RD:
        begin
        busy <= 1;
        if (bit cnt == 0) begin
        if (ena == 1 && addr_rw == {addr,rw}) sda_int <= 0;
        else sda int <= 1;
        bit cnt <= 3'd7;
        data rd <= data rx;
        state <= MSTR ACK;
        end
        else if (bit_cnt == 1)
        begin
        bit cnt <= bit cnt - 1;
        eop <= 1;
        end
        else
        begin
        bit_cnt <= bit_cnt - 1;
        state <= RD;
        end
        end
SLV ACK2 :
        if (ena == 1)
        begin
        eop <= 0;
        busy <= 0;
        addr_rw <= {addr,rw};
        data_tx <= data_wr;
        if (addr_rw == {addr,rw})
        begin
        sda int <= data wr[bit cnt];
        state <= WR;
        end
        else state <= START;
        end
        else
        begin
        eop <= 0;
        state <= STOP;
        end
MSTR ACK:
        if (ena == 1)
        begin
        eop <= 0;
        busy = 0;
        addr_rw <= {addr,rw};
        data tx <= data wr;
        if (addr rw == {addr,rw})
        begin
        sda int <= 1;
        state <= RD;
        end
        else state <= START;
        end
        else
        begin
        eop <= 0;
        state <= STOP;
        end
STOP:
        begin
        busy <= 0;
        state <= READY;
        end
```

我们可以将I²C主控模块的工作原理解释为状态机。该状态机包含九个状态：READY（就绪）、START（起始）、COMMAND（命令）、SLV_ACK1（从机应答1）、WR（写入）、RD（读取）、SLV_ACK2（从机应答2）、MSTR_ACK（主机应答）和STOP（停止）。  

状态机从**READY**状态开始，等待**ena**信号变为逻辑1。当**ena**有效时：  
- **busy**信号置为逻辑1  
- 从机地址与**rw**位组合写入**addr_rw**向量  
- **data_wr**数据存入**data_tx**向量  
- 状态转为**START**  

在**START**状态下，**addr_rw**向量的最高位被加载到**sda_int**（该信号直接控制**sda**端口），随后状态转入**COMMAND**。在此状态下，**addr_rw**向量通过**sda**线逐位传输。传输完成后，主控模块进入**SLV_ACK1**状态等待从机应答——此时从机需将**sda**线拉至逻辑0以示响应。若未收到应答，**ack_error**将置为逻辑1。  

下一状态由**rw**输入决定：  
- 若**rw**为逻辑1，状态机进入**RD**（读取）状态，逐位接收数据并存入**data_rd**向量。当位计数器减至1时，**eop**置为逻辑1表示数据包接收完成；位计数器归零后，状态转为**MSTR_ACK**，主机会发送接收确认。  
- 若**rw**为逻辑0，状态机进入**WR**（写入）状态，将**data_tx**向量数据通过**sda_int**逐位发送。位计数器为1时**eop**有效；全部数据发送后转入**SLV_ACK2**状态等待从机应答。  

在**SLV_ACK2**和**MSTR_ACK**状态下：  
- 若**ena**仍为逻辑1，则新的从机地址和**rw**位会写入**addr_rw**向量。若与之前值相同，状态机返回**START**实现重复起始条件；否则转入**STOP**状态，在I²C总线上生成停止信号，最终回到**READY**等待下一次传输。  

在上面的代码的I²C主控模块中，我们使用数据流建模的条件语句（如描述最后两行所示）。其结构为：  

```verilog
assign variable = condition ? 0/1 : value_to_be_assigned;
```

这种表达方式也可应用于其他Verilog描述中。  

---

## LVDS技术详解及其在FPGA中的应用

### LVDS技术概述

LVDS（Low-Voltage Differential Signaling，低电压差分信号）是一种用于高速数据传输的接口技术，由美国国家半导体（NS）于1994年提出。目前LVDS技术广泛应用于显示、通信、工业控制等领域。其核心特点是通过差分信号传输数据，利用低电压摆幅和电流驱动实现高性能信号传输。LVDS的基本特点如下表所示：

| 特性         | 参数值               |
|--------------|---------------------|
| 电压幅值     | 典型350mV（差分）    |
| 传输速率     | 可达3.125Gbps以上    |
| 功耗         | 比CMOS/TTL低10倍    |
| 抗干扰能力   | 强（共模抑制比高）   |

---

### LVDS工作原理详细说明

LVDS技术的核心是通过差分信号传输机制实现高可靠性通信。以下从**差分信号传输**和**电气特性**两个方面展开说明。

---

#### 一、差分信号传输机制

##### 基本流程（结合图示）
```mermaid
graph LR
    单端信号1[单端信号] --> 驱动电路
    驱动电路 -->|LVDS+| 接收电路
    驱动电路 -->|LVDS-| 接收电路
    接收电路 --> 单端信号2[单端信号]

    subgraph 发送端
        驱动电路[驱动电路]
    end

    subgraph 接收端
        接收电路[接收电路]
    end
```

- **发送端**：
  - **单端信号输入**：输入信号为单端逻辑电平（如TTL/CMOS电平）。
  - **差分转换**：驱动电路将单端信号转换为一对互补的差分信号（LVDS+和LVDS-），两者幅值相等、极性相反。
    - 逻辑"1"：LVDS+ > LVDS-（典型差值约350mV）。
    - 逻辑"0"：LVDS+ < LVDS-。

- **传输通道**：
  - 差分信号通过双绞线或PCB差分对传输，两条线紧密耦合，外部噪声会被共模抑制。

- **接收端**：
  - **差分比较**：接收电路（差分放大器）比较LVDS+和LVDS-的电压差，恢复为单端信号。
  - 噪声抑制：由于差分信号的共模噪声（如电磁干扰）在两条线上表现一致，接收端通过减法运算消除共模噪声。

##### 关键优势

- **抗干扰能力**：差分传输对外部噪声具有天然免疫力。
- **低电磁辐射（EMI）**：互补信号产生的磁场相互抵消，减少辐射。
- **高速传输**：差分信号的电压摆幅小（典型350mV），支持更高切换速率（可达Gbps级）。

---

#### 电气特性详解

1. 差分阻抗（Differential Impedance）
   - **典型值**：100Ω（需与传输线阻抗匹配）。
   - **作用**：
     - 确保信号完整性，避免反射导致的信号畸变。
     - 实现功率匹配，最大化信号传输效率。
   - **设计要点**：
     - PCB设计时需严格控制差分对的线宽、线距和介质厚度，以满足100Ω阻抗要求。
     - 接收端通常并联100Ω终端电阻，吸收反射能量。
2. 共模电压（Common-Mode Voltage）
   - **典型值**：1.2V（以地为参考）。
   - **定义**：差分信号对（LVDS+和LVDS-）的平均电压。
   - **作用**：
     - 确保接收端电路在共模电压范围内正常工作。
     - 提供稳定的偏置点，避免信号超出接收器输入范围。
   - **设计要点**：
     - 发送端需通过偏置电路维持共模电压稳定（如1.2V）。
     - 接收端需支持宽共模范围（通常±1V），以适应系统噪声和电压漂移。
3. 摆率（Slew Rate）
   - **范围**：0.3-1.5ns（指电压从10%到90%的上升/下降时间）。
   - **意义**：
     - 控制信号边沿的陡峭程度，直接影响信号带宽和EMI性能。
     - 较低的摆率（较慢的边沿）可减少高频分量，降低电磁辐射。
   - **设计权衡**：
     - 摆率过高：增加高频噪声和EMI。
     - 摆率过低：限制最大传输速率。

LVDS通过**差分信号传输**和**精密电气特性设计**，实现了高速、低功耗、高抗干扰的通信。其核心在于利用差分对的互补性和共模抑制能力，结合优化的阻抗、共模电压和摆率控制，成为现代高速数字系统的关键技术之一。

---


### LVDS技术特点详细说明

LVDS技术核心特点包括**低功耗**（静态电流低至1.5mA）、**Gbps级高速传输**、**强抗干扰能力**（抑制共模噪声）和**低电磁辐射（EMI）**，适用于显示、工业控制等短距离高速场景；但其设计需**严格阻抗匹配**（通常100Ω），仅支持**点对点连接**，且**传输距离受限**（通常<10米），长距离需借助中继或改用其他协议。
以下是其优势和局限性的详细分析：

---

#### **优势**  

1. **低功耗**  
   - **原理**：LVDS采用低压摆幅（典型值约350mV）和恒流源驱动（通常3.5mA），静态电流仅1.5mA，显著降低功耗。  
   - **应用场景**：适合便携式设备（如笔记本电脑、平板）、电池供电系统或需要长时间运行的场景。  
   - **对比优势**：相比传统CMOS或TTL电平（电压摆幅达数伏），功耗降低数十倍。

2. **高速传输（Gbps级）**  
   - **原理**：差分信号通过两条相位相反的信号线传输，减少信号跳变时间，支持高频率（可达数GHz）。  
   - **典型速率**：单通道可达3.125 Gbps，多通道并行可实现更高带宽（如FPD-Link技术）。  
   - **应用场景**：高清视频传输（如车载显示屏、医疗成像）、高速数据采集（如雷达、示波器）。

3. **强抗干扰能力**  
   - **原理**：差分信号对共模噪声（如电源波动、环境电磁干扰）具有天然抑制能力。两条信号线的噪声会被接收端抵消。  
   - **可靠性**：在工业环境、汽车电子等高噪声场景中表现优异，误码率低。

4. **低EMI辐射**  
   - **原理**：低电压摆幅和电流驱动模式减少了电磁辐射；差分信号产生的磁场相互抵消，进一步降低EMI。  
   - **合规性**：更容易通过FCC、CISPR等电磁兼容性认证，适合对EMI敏感的系统（如医疗设备）。

---

#### **局限性**

1. **需要严格阻抗控制**  
   - **设计要求**：LVDS要求差分阻抗匹配（通常100Ω±10%），否则会导致信号反射和失真。  
   - **实现难点**：PCB设计需精确计算线宽、间距及叠层结构，需使用阻抗测试工具验证。  
   - **成本影响**：增加了设计复杂度及制造成本，尤其在多层板或高频材料中。

2. **点对点拓扑限制**  
   - **拓扑约束**：LVDS仅支持单一发送端到单一接收端的点对点连接，无法直接实现总线型或多节点通信。  
   - **扩展方案**：需通过中继器、交换芯片或桥接电路扩展拓扑，但会引入延迟和成本。

3. **传输距离有限（通常<10m）**  
   - **物理限制**：长距离传输时，信号衰减和抖动加剧，导致误码率上升。  
   - **解决方案**：可通过电缆均衡、中继器延长至数十米，但需权衡成本和复杂度；更长距离需改用光纤或其他协议（如RS-485）。

---

#### **LVDS技术特点总结**

| **维度**       | **LVDS优势**                          | **LVDS局限性**                      |
|----------------|---------------------------------------|-------------------------------------|
| **功耗**       | 超低静态功耗，适合移动设备            | -                                   |
| **速率**       | Gbps级传输，满足高速需求              | 长距离下速率受限                    |
| **抗干扰**     | 高可靠性，适合复杂电磁环境            | -                                   |
| **设计复杂度** | -                                     | 需严格阻抗控制，增加设计难度        |
| **扩展性**     | -                                     | 点对点拓扑限制多节点应用            |

**替代技术选择**：  

- 长距离传输：改用光纤、RS-485或以太网。  
- 多节点总线：CAN、I2C或MIPI联盟的C-PHY。  

LVDS在短距离、高速、低功耗场景中优势显著，但需在设计初期权衡其拓扑和阻抗控制要求。

---

### FPGA中的LVDS支持

#### 主流FPGA支持情况

| 厂商   | 系列示例          | LVDS支持情况                     |
|--------|-------------------|----------------------------------|
| Xilinx | Artix-7/Kintex-7  | 支持，需使用SelectIO资源         |
| Intel  | Cyclone 10 GX     | 内置LVDS收发器                   |
| Lattice| ECP5             | 支持LVDS/SLVS等差分标准          |

#### FPGA LVDS接口实现

```verilog
// Xilinx FPGA LVDS示例
OBUFDS lvds_tx_inst (
    .O(lvds_p),    // 正相输出
    .OB(lvds_n),   // 反相输出
    .I(tx_data)    // 内部单端信号
);

IBUFDS lvds_rx_inst (
    .O(rx_data),   // 内部单端信号
    .I(lvds_p),    // 正相输入
    .IB(lvds_n)    // 反相输入
);
```

---

### LVDS在FPGA中的典型应用
#### 高速数据传输
- 摄像头接口（如MIPI D-PHY）
- 显示接口（LCD面板驱动）
- 板间高速互联

#### 时钟分配

```mermaid
graph LR
    A[FPGA Master] -- LVDS --> B[FPGA Slave]
    A -- LVDS --> C[ADC]
```


#### 具体案例：LVDS SerDes
```verilog
// 7:1串行化示例
parameter RATIO = 7;
reg [RATIO-1:0] parallel_data;
reg [2:0] count = 0;

always @(posedge lvds_clk) begin
    lvds_tx <= parallel_data[count];
    count <= (count == RATIO-1) ? 0 : count + 1;
end
```

---

#### LVDS系统设计要点

1. **阻抗匹配**：必须确保传输线、终端电阻与差分阻抗一致（100Ω）。
2. **共模稳定性**：通过偏置电路或共模反馈维持共模电压。
3. **噪声抑制**：
   - 使用屏蔽双绞线或严格PCB布线规则。
   - 避免差分对与其他信号线平行走线。
4. **功耗优化**：LVDS采用电流驱动（典型3.5mA），功耗显著低于电压驱动技术（如RS-422）。

---

#### LVDS的PCB设计要点

- 保持差分对等长（ΔL < 5mil）
- 避免90°拐角（建议45°或圆弧）
- 参考平面完整（避免跨分割）

#### LVDS终端匹配

```mermaid
graph LR
    LVDS+ -- 差分对 --- R[100Ω电阻] --- LVDS-
    R -- 中心抽头 --- V[[1.2V共模电压]]
```

#### LVDS常见问题解决

| 问题现象       | 可能原因               | 解决方案               |
|----------------|------------------------|------------------------|
| 信号完整性差   | 阻抗不匹配             | 检查走线阻抗           |
| 数据误码       | 时钟抖动大             | 优化时钟树/使用CDR     |
| 无法锁定       | 共模电压超出范围       | 检查终端电路           |

---

LVDS作为高速差分传输技术，在FPGA应用中具有显著优势：

- 适合Gbps级数据传输
- 显著降低系统功耗
- 提升抗干扰能力

未来随着SerDes技术发展，LVDS将继续在工业、医疗和通信领域发挥重要作用。

---

## **FPGA实现HDMI接口的设计流程**

### **硬件设计**

- **HDMI接口电路**：
  - 使用专用HDMI电平转换芯片（如Analog Devices的ADV7511或Silicon Image的SiI9136），将FPGA输出的低压差分信号（LVDS）转换为HDMI标准TMDS信号。
  - 电路需满足阻抗匹配（100Ω差分阻抗）、ESD保护和电磁兼容性（EMC）要求。
- **FPGA选型**：需支持高速串行接口（如Xilinx Artix-7/Kintex系列或Intel Cyclone V/10系列），并具备足够的逻辑资源与I/O速度。

好的！TMDS（Transition Minimized Differential Signaling，最小化传输差分信号）是HDMI和DVI接口中用于高速数字视频传输的核心编码技术。其核心目标是通过减少信号跳变（Transition）和保持直流平衡（DC Balance），降低电磁干扰（EMI）并提高信号完整性。以下是TMDS编码的详细解析：

---

### **1. HDMI接口基本原理**

HDMI（High-Definition Multimedia Interface）是一种数字音视频传输协议，支持高分辨率视频（如1080p、4K）和多声道音频。其核心特点包括：

- **物理层**：基于TMDS（Transition Minimized Differential Signaling）差分信号传输，通过3对数据通道（Data0/1/2）和1对时钟通道（Clock）实现高速串行通信。
- **协议层**：视频数据采用RGB或YCbCr格式编码，音频和辅助数据（如EDID、HDCP）通过数据岛（Data Island）传输。
- **版本差异**：不同版本（如HDMI 1.4/2.0/2.1）支持的分辨率、刷新率和带宽不同（例如HDMI 2.0支持18Gbps带宽，可传输4K@60Hz）。

---

### **TMDS编码的核心原理**

#### **主要目标**
- **减少信号跳变**：通过编码使相邻比特位之间的电平变化（0→1或1→0）最小化，降低EMI。
- **直流平衡**：编码后的数据流中0和1的数量接近平衡，避免信号因长期偏置（如过多0或1）导致电压漂移。
- **时钟恢复**：接收端可通过数据流中的跳变提取同步时钟。

#### **编码流程**

TMDS编码分为两个阶段：**8b/10b编码**和**差分传输**。
1. **8b/10b编码**：将8位像素数据转换为10位符号。
2. **差分传输**：通过一对差分线（如Data0+/Data0-）传输10位符号。

---

### **8b/10b编码的详细步骤**

#### **输入数据分类**

- **视频数据（Video Period）**：有效像素数据（RGB/YCbCr）。
- **控制数据（Control Period）**：同步信号（HSYNC/VSYNC）和消隐期。
- **数据岛（Data Island Period）**：音频和辅助数据包。

不同数据类型使用不同的编码模式。

#### **编码过程**

##### **步骤1：判断编码模式**

- **视频数据模式**：对8位像素数据进行最小化跳变编码。
- **控制模式**：使用固定的10位控制字符（如`0b1101010100`表示HSYNC和VSYNC的组合）。

##### **步骤2：最小化跳变编码（仅视频数据）**

1. **异或（XOR）或异或非（XNOR）选择**：
   - 比较当前8位数据的跳变次数，选择XOR或XNOR操作，使跳变次数最少。
   - **规则**：若输入数据中0的数量 > 4，或0的数量=4且最低位为0，则使用XNOR，否则使用XOR。
2. **生成9位中间数据**：
   - 第9位（q_m）表示使用的操作类型（0=XOR，1=XNOR）。

**公式示例**（以XOR为例）：

```verilog
q_out[0] = D[0]
q_out[1] = q_out[0] ^ D[1]
...
q_out[8] = 0  // 表示使用XOR
```

##### **步骤3：直流平衡调整**

- 统计已传输数据中1和0的数量差（偏差值）。
- 根据偏差值选择是否反转10位符号：
  - 若偏差值过大（>0或<0），则反转符号（0→1，1→0），并设置第10位为1表示反转。
  - 否则保持原符号，第10位为0。

**最终10位符号格式**：

```verilog
符号 = {反转标志位, q_m[8:0]}
```

#### **控制字符编码**

在消隐期或同步阶段，直接使用预定义的10位控制字符：

- **HSYNC和VSYNC组合**：例如`0b1101010100`。
- **数据岛包头**：特定控制字符标识音频或辅助数据的开始。

---

### **TMDS编码示例**

#### **示例1：视频数据编码**

假设输入像素数据为`8'b10101010`：

1. **计算跳变次数**：
   - 数据`10101010`的相邻位跳变为7次（1→0→1→0→1→0→1→0）。
2. **选择XOR或XNOR**：
   - 0的数量=4，最低位为0 → 使用XNOR。
3. **生成中间符号**：

```verilog
q_m[0] = D[0] = 0
q_m[1] = q_m[0] XNOR D[1] = 0 XNOR 1 = 0
...
q_m[8] = 1  // 表示使用XNOR
```

1. **直流平衡调整**：假设当前偏差为+2，反转符号并设置第10位为1。

#### **示例2：控制字符编码**

发送HSYNC=1和VSYNC=0：
- 直接映射到预定义控制字符`0b1101010100`。

---

### **TMDS编码的硬件实现**

#### **FPGA逻辑设计**

- **核心模块**：查表法（LUT）或状态机实现编码逻辑。
- **流水线优化**：将XOR/XNOR选择、偏差计算和符号生成分为多级流水线。

#### **Verilog代码片段**

```verilog
module tmds_encoder (
    input clk,
    input [7:0] data,
    input [1:0] ctrl,  // 控制信号（HSYNC, VSYNC）
    output reg [9:0] tmds
);
    // 计算跳变次数和0的数量
    wire [3:0] zeros = count_zeros(data);
    wire use_xnor = (zeros > 4) || (zeros == 4 && data[0] == 0);

    // 生成中间符号q_m
    reg [8:0] q_m;
    always @(*) begin
        if (use_xnor) begin
            q_m[0] = data[0];
            q_m[1] = q_m[0] ~^ data[1];
            // ... 依次生成q_m[2]到q_m[7]
            q_m[8] = 1'b1;  // 表示XNOR
        end else begin
            // 类似逻辑使用XOR
        end
    end

    // 直流平衡调整
    reg [9:0] bias = 0;
    always @(posedge clk) begin
        if (ctrl != 2'b00) begin
            // 控制模式：直接输出预定义字符
            tmds <= {2'b00, ctrl, 6'b010100};  // 示例控制字符
        end else begin
            // 视频模式：计算是否反转
            if (bias == 0 || (q_m[4:0] > 5'b10000)) begin
                tmds <= {1'b1, ~q_m};
                bias <= bias - (10 - 2*$countones(q_m));
            end else begin
                tmds <= {1'b0, q_m};
                bias <= bias + (2*$countones(q_m) - 10);
            end
        end
    end
endmodule
```

---

### **TMDS的物理层传输**

- **差分信号**：每个TMDS通道（Data0/1/2和Clock）通过一对差分线传输，抗干扰能力强。
- **时钟通道**：传输像素时钟的10倍频（例如1080p@60Hz需要148.5MHz像素时钟，时钟通道为1.485GHz）。

---

### **设计挑战与优化**

1. **时序收敛**：
   - 需在FPGA中约束高速串行时钟（如1.485GHz），确保建立/保持时间满足。
2. **资源占用**：
   - 使用FPGA专用串行化器（如Xilinx的OSERDESE2）降低逻辑复杂度。
3. **信号完整性**：
   - PCB设计需保证差分对等长（长度差<5mil），避免阻抗失配。

---

TMDS编码通过8b/10b转换、最小化跳变和直流平衡机制，实现了高可靠性的数字视频传输。在FPGA设计中，需结合查表法、状态机和流水线优化，同时严格管理时序和信号完整性。理解TMDS编码细节是开发HDMI接口的关键基础。

#### ** 逻辑设计**

##### **核心模块划分**

1. **视频数据处理模块**：
   - 接收外部输入的视频数据（如摄像头或内存中的RGB/YUV数据）。
   - 进行分辨率适配（缩放或裁剪）、色彩空间转换（如RGB转YCbCr 4:4:4）和时序生成（同步信号HSYNC/VSYNC）。

2. **TMDS编码模块**：
   - 对视频数据进行**8b/10b编码**，增加直流平衡和时钟恢复能力。
   - 编码公式：每个8位像素值通过查表或逻辑运算转换为10位TMDS符号。
   - 控制信号（如DE（Data Enable））需与像素时钟严格同步。

3. **并串转换（Serializer）**：
   - 使用FPGA的专用串行化资源（如Xilinx的OSERDES或Intel的LVDS SERDES），将并行数据转换为高速串行TMDS信号。
   - 时钟要求：串行化时钟频率 = 像素时钟 × 10（例如1080p@60Hz的像素时钟为148.5MHz，串行时钟需1.485GHz）。

4. **音频与辅助数据传输**：
   - 音频数据需打包为I2S格式，并通过数据岛周期插入视频消隐区。
   - 实现EDID（Extended Display Identification Data）读写，用于显示器参数识别。

5. **时钟管理**：
   - 使用FPGA的PLL或MMCM生成精确的像素时钟和串行化时钟。
   - 需解决跨时钟域问题（如视频数据与音频数据的时钟同步）。

##### **代码结构示例（VHDL/Verilog）**

```verilog
// TMDS编码模块示例
module tmds_encoder (
    input clk,
    input [7:0] data,
    input ctrl,
    output reg [9:0] tmds
);
    // 8b/10b编码逻辑（查表或算法实现）
    // ...
endmodule

// 顶层HDMI控制器
module hmi_controller (
    input clk_pixel,
    input [23:0] rgb,
    output tmds_clk,
    output [2:0] tmds_data
);
    // 实例化编码器、时钟管理、并串转换等模块
    // ...
endmodule
```

---

### ** 验证与调试**

- **仿真验证**：
  - 使用ModelSim或Vivado Simulator验证TMDS编码和时序逻辑。
  - 生成测试向量（如渐变彩条图案）模拟视频输入。
- **硬件测试**：
  - 通过示波器或逻辑分析仪捕获TMDS信号眼图，验证信号完整性。
  - 使用HDMI协议分析仪（如Teledyne LeCroy的PeHDMI）解析数据包内容。

---

### ** 挑战与优化**

1. **时序约束**：
   - 需在FPGA中设置严格的时序约束（如set_input_delay/set_output_delay），确保数据与时钟对齐。
2. **信号完整性**：
   - 差分走线等长控制（长度差<5mil），避免反射和串扰。
3. **资源优化**：
   - 使用FPGA专用硬核（如Xilinx的GTP/GTX收发器）降低逻辑资源占用。
   - 通过流水线设计提高吞吐量。

---

### **5. 应用场景**

- **视频处理设备**：如视频采集卡、图像发生器。
- **嵌入式显示系统**：工业HMI、医疗显示终端。
- **消费电子原型开发**：游戏机、VR设备的前期验证。

---

基于FPGA的HDMI接口设计需要综合硬件电路设计、高速信号处理和严格的时序控制，核心在于TMDS编码、并串转换和时钟管理。通过模块化设计和仿真验证，可高效实现高清视频传输，适用于定制化视频系统开发。
