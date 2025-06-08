---
title: "第3讲：开源Verilog综合工具"
author: [周贤中]
date: 2025-03-30
subject: "Markdown"
keywords: [FPGA, 系统设计]
lang: "zh-cn"
...

---

## 开源硬件综合工具介绍

### Yosys：Verilog逻辑综合引擎
<!-- [![GitHub Stars](https://img.shields.io/github/stars/YosysHQ/yosys)](https://github.com/YosysHQ/yosys) -->

#### 核心架构

```mermaid
graph LR
    A["RTL (Verilog)"] --> B["Yosys"]
    B --> C["技术映射"]
    C --> D["网表 (BLIF/EDIF)"]
```

---

#### 功能特性

- **多前端支持**：Verilog-2005, SystemVerilog（部分）
- **综合策略**：行为级/逻辑级/门级优化
- **插件生态**：20+官方插件（如`proc`, `fsm`）

---

#### Ubuntu安装

```bash yosys_install.sh
sudo apt install yosys         # 稳定版
sudo apt install yosys-next    # 开发版（Ubuntu 22.04+）
```

---

### OpenROAD：物理综合工具链

#### 完整RTL2GDS流程
```bash openroad_flow.sh
./flow.tcl -design aes_cipher \
           -platform nangate45 \
           -clock_period 2.5
```

---

#### 主要阶段
1. **逻辑优化**（Yosys）
2. **布局规划**（IO布置）
3. **时钟树综合**
4. **详细布线**

---

### 工具链对比矩阵

| 特性            | Yosys      | GHDL       | OpenROAD   |
|------------------|------------|------------|------------|
| 输入语言         | Verilog    | VHDL       | Verilog    |
| 综合层次         | 逻辑级     | 行为级     | 物理级     |
| 布局布线         | ✗          | ✗          | ✓          |
| 工艺库支持       | Liberty    | ✗          | LEF/DEF    |
| 可视化调试       | 有限       | GTKWave    | GUI        |

---

### 开发环境配置建议

```dockerfile eda.dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    yosys \
    ghdl \
    gtkwave \
    nextpnr-ice40

WORKDIR /project
```

---

### 扩展资源
- [Yosys Manual](https://yosyshq.readthedocs.io/en/latest/)
- [GHDL Documentation](https://ghdl.github.io/ghdl/)
- [OpenROAD Workshop](https://theopenroadproject.org/workshops/)

---

## Yosys使用教程

### Yosys 简介
Yosys 最初是 Claire Wolf 的本科毕业论文项目，旨在支持一种粗粒度可重构架构（CGRA）的综合。随后，它扩展为一个更通用的综合研究基础设施。

现代的 Yosys 完全支持 Verilog-2005 的可综合子集，并被描述为“硬件综合领域的 GCC”。Yosys 是免费且开源的，广泛应用于业余爱好者、商业应用以及学术领域。

Yosys 及其伴随的开源 EDA 生态系统目前由 **Yosys Headquarters** 维护，许多核心开发者受雇于 YosysHQ GmbH。其商业扩展版本 **Tabby CAD Suite** 包括 Verific 前端，提供行业级的 SystemVerilog 和 VHDL 支持、基于 SVA 的形式验证以及形式化应用程序。

---

### 你可以用 Yosys 做什么
1. **读取和处理现代 Verilog-2005 代码（大部分）**  
   Yosys 支持 Verilog-2005 的可综合子集，能够解析和处理大部分现代 Verilog 代码。

2. **对网表（RTL、逻辑、门级）执行各种操作**  
   Yosys 提供了丰富的工具和命令，可以对网表进行转换、优化和分析。

3. **使用 ABC 进行逻辑优化和门级映射**  
   Yosys 集成了 ABC 工具，能够执行逻辑优化和门级映射，生成高效的硬件实现。

---

### Yosys 的典型应用
1. **最终生产设计的综合**  
   Yosys 可以用于生成最终生产设计的综合结果。

2. **预生产综合（在投资其他工具之前进行试运行）**  
   在正式使用商业工具之前，Yosys 可以用于试运行和验证设计。

3. **将功能齐全的 Verilog 转换为简单的 Verilog**  
   Yosys 能够将复杂的 Verilog 设计简化为更易于理解和处理的版本。

4. **将 Verilog 转换为其他格式（如 BLIF、BTOR 等）**  
   Yosys 支持将 Verilog 设计转换为多种中间格式，便于与其他工具集成。

5. **演示综合算法（例如用于教育目的）**  
   Yosys 是一个理想的平台，用于展示和教学硬件综合算法。

6. **实验新算法的框架**  
   Yosys 提供了灵活的框架，支持开发和测试新的综合算法。

7. **构建自定义流程的框架（不仅限于综合，还包括形式验证、逆向工程等）**  
   Yosys 的模块化设计使其能够用于构建各种自定义流程，涵盖形式验证、逆向工程等领域。

---

### Yosys 不能做什么
1. **处理高级语言（如 C/C++/SystemC）**  
   Yosys 不支持直接从 C/C++/SystemC 等高级语言进行综合。

2. **创建物理布局（布局布线）**  
   Yosys 不包含物理布局和布线功能。如果需要这些功能，可以结合使用 **nextpnr** 工具。

3. **依赖内置语法检查**  
   Yosys 的语法检查功能有限，建议使用外部工具（如 **Verilator**）进行更严格的语法检查。

---

### Yosys安装
在WSL系统中，直接利用下面这个命令就可以安装Yosys
```bash
sudo apt-get install yosys		#ubuntu24.04仓库里面是yosys-0.33
```

### 综合入门

本页将引导您完成预打包的 iCE40 FPGA 综合脚本 `synth_ice40` 的使用。我们将通过一个简单的设计逐步讲解每个步骤，查看调用的命令及其对设计的影响。虽然 `synth_ice40` 是针对 iCE40 平台的，但我们将讨论的大多数操作在大多数 FPGA 综合脚本中都是通用的。因此，无论实际使用的架构是什么，本文档都将为您提供 Yosys 中综合操作的良好基础理解。


### 示例设计

首先，让我们快速看一下我们将要综合的设计：

**代码清单 1**  
`fifo.v`

```verilog
// 地址生成器/计数器
module addr_gen 
#(  parameter MAX_DATA=256,
	localparam AWIDTH = $clog2(MAX_DATA)
) ( input en, clk, rst,
	output reg [AWIDTH-1:0] addr
);
	initial addr = 0;

	// 异步复位
	// 当使能时递增地址
	always @(posedge clk or posedge rst)
		if (rst)
			addr <= 0;
		else if (en) begin
			if ({'0, addr} == MAX_DATA-1)
				addr <= 0;
			else
				addr <= addr + 1;
		end
endmodule //addr_gen

// 定义我们的顶层 fifo 实体
module fifo 
#(  parameter MAX_DATA=256,
	localparam AWIDTH = $clog2(MAX_DATA)
) ( input wen, ren, clk, rst,
	input [7:0] wdata,
	output reg [7:0] rdata,
	output reg [AWIDTH:0] count
);
	// fifo 存储
	// 同步读优先于写
	wire [AWIDTH-1:0] waddr, raddr;
	reg [7:0] data [MAX_DATA-1:0];
	always @(posedge clk) begin
		if (wen)
			data[waddr] <= wdata;
		rdata <= data[raddr];
	end // storage

	// 用于写和读地址的 addr_gen
	addr_gen #(.MAX_DATA(MAX_DATA))
	fifo_writer (
		.en     (wen),
		.clk    (clk),
		.rst    (rst),
		.addr   (waddr)
	);

	addr_gen #(.MAX_DATA(MAX_DATA))
	fifo_reader (
		.en     (ren),
		.clk    (clk),
		.rst    (rst),
		.addr   (raddr)
	);

	// 状态信号
	initial count = 0;

	always @(posedge clk or posedge rst) begin
		if (rst)
			count <= 0;
		else if (wen && !ren)
			count <= count + 1;
		else if (ren && !wen)
			count <= count - 1;
	end

endmodule
```
---

### **1. 模块 `addr_gen`（地址生成器/计数器）**
#### **功能概述**
这是一个循环地址生成器，用于生成递增的地址信号。当使能信号 `en` 有效且未达到最大地址时，地址递增；到达最大值后自动归零。支持异步复位。

#### **关键代码分析**
- **参数定义**
  ```verilog
  parameter MAX_DATA = 256;        // 最大地址范围（默认256）
  localparam AWIDTH = $clog2(MAX_DATA); // 地址位宽（自动计算，如256对应8位）
  ```
  - `MAX_DATA` 定义地址范围（0 到 `MAX_DATA-1`）。
  - `$clog2` 是 SystemVerilog 函数，计算地址位宽。例如，`MAX_DATA=256` 时，`AWIDTH=8`。

- **地址更新逻辑**
  ```verilog
  always @(posedge clk or posedge rst) begin
    if (rst) 
      addr <= 0;                 // 异步复位，地址归零
    else if (en) begin
      if ({'0, addr} == MAX_DATA-1)
        addr <= 0;               // 到达最大地址时归零
      else
        addr <= addr + 1;        // 正常递增
    end
  end
  ```
  - **异步复位**：`rst` 信号优先于时钟，直接清零地址。
  - **地址递增**：在 `en` 有效时递增地址。
  - **循环逻辑**：`{'0, addr}` 将 `addr` 扩展为足够宽的整数，确保比较正确。当地址达到 `MAX_DATA-1` 时归零。

#### **潜在问题**
- 若 `MAX_DATA` 不是 2 的幂（如 200），`AWIDTH` 会向上取整（如 8 位），此时实际地址范围是 0-255，但 `MAX_DATA-1=199`，导致 200-255 的地址无法被使用，可能浪费存储空间。需确保 `MAX_DATA` 是 2 的幂。

---

### **2. 模块 `fifo`（同步 FIFO）**
#### **功能概述**
实现一个同步 FIFO（First-In-First-Out）队列，支持同时读写，读优先于写。通过两个 `addr_gen` 实例分别管理读写地址，并维护数据计数器 `count`。

#### **关键代码分析**
- **存储结构**
  ```verilog
  reg [7:0] data [MAX_DATA-1:0]; // 存储器，深度 MAX_DATA，位宽 8
  always @(posedge clk) begin
    if (wen)
      data[waddr] <= wdata;      // 写操作
    rdata <= data[raddr];        // 读操作（同步读）
  end
  ```
  - **写操作**：在 `wen` 有效时，将 `wdata` 写入 `waddr` 地址。
  - **读操作**：每个周期更新 `rdata` 为 `raddr` 地址的值（同步读）。

- **地址生成器实例化**
  ```verilog
  addr_gen #(.MAX_DATA(MAX_DATA)) fifo_writer (.en(wen), ...); // 写地址生成
  addr_gen #(.MAX_DATA(MAX_DATA)) fifo_reader (.en(ren), ...); // 读地址生成
  ```
  - 写地址 `waddr` 在 `wen` 有效时递增。
  - 读地址 `raddr` 在 `ren` 有效时递增。

- **计数器 `count` 逻辑**
  ```verilog
  always @(posedge clk or posedge rst) begin
    if (rst)
      count <= 0;                     // 复位清零
    else if (wen && !ren)
      count <= count + 1;             // 只写不读，计数加1
    else if (ren && !wen)
      count <= count - 1;             // 只读不写，计数减1
  end
  ```
  - `count` 表示 FIFO 中当前数据数量，位宽为 `AWIDTH+1`（例如 MAX_DATA=256 时，`count` 是 9 位，范围 0-256）。
  - 同时读写时 `count` 不变。

#### **同步读写特性**
- **读优先于写**：在同一个时钟周期内，写入的数据在下一周期才能被读取，确保当前周期读取的是旧数据。
- **无空满保护**：代码未检查 `count` 的边界（如 `count == 0` 时禁止读，`count == MAX_DATA` 时禁止写），需外部逻辑处理。

#### **潜在问题**
- **溢出/下溢风险**：若在 FIFO 已满时继续写入（或为空时继续读取），会导致数据覆盖或无效读取。需添加 `full` 和 `empty` 信号。

---

### **整体设计总结**
- **地址生成器**：循环生成读写地址，支持异步复位。
- **FIFO 存储**：同步读写，读操作优先。
- **计数器逻辑**：跟踪 FIFO 中数据数量，但缺少空满保护。
- **扩展性建议**：
  - 添加 `full` 和 `empty` 信号：`full = (count == MAX_DATA)`，`empty = (count == 0)`。
  - 若需支持非 2 的幂次 `MAX_DATA`，需修改地址生成器的循环条件。

通过这段代码，可以学习到同步 FIFO 的基本实现方法，包括地址管理、数据存储和状态跟踪。

---

### **1. 测试平台结构**

**代码清单 2**  
`fifo_tb.v`

```verilog
module fifo_tb;
    // 测试参数设置
    parameter MAX_DATA = 4;       // 使用较小深度便于测试
    localparam AWIDTH = $clog2(MAX_DATA);
    
    // 输入信号
    reg clk, rst;
    reg wen, ren;
    reg [7:0] wdata;
    
    // 输出信号
    wire [7:0] rdata;
    wire [AWIDTH:0] count;
    
    // 实例化被测FIFO
    fifo #(.MAX_DATA(MAX_DATA)) dut (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .ren(ren),
        .wdata(wdata),
        .rdata(rdata),
        .count(count)
    );
    
    // 生成时钟（周期10ns）
    initial clk = 0;
    always #5 clk = ~clk;
    
    // 主测试流程
    initial begin
        // 初始化信号
        wen = 0;
        ren = 0;
        wdata = 0;
        rst = 1;
        
        // 复位操作（15ns后释放）
        #15 rst = 0;
        
        // 测试用例1：基本写操作
        $display("\n=== Test 1: Basic write ===");
        wen = 1;
        repeat(MAX_DATA) begin
            wdata = $random;
            @(posedge clk);
            #1;
            $display("Write: 0x%h | Count: %0d", wdata, count);
        end
        wen = 0;
        
        // 验证计数
        if(count !== MAX_DATA)
            $display("Error: Expected count %0d, got %0d", MAX_DATA, count);
        
        // 测试用例2：基本读操作
        $display("\n=== Test 2: Basic read ===");
        ren = 1;
        repeat(MAX_DATA) begin
            @(posedge clk);
            #1;
            $display("Read: 0x%h | Count: %0d", rdata, count);
        end
        ren = 0;
        
        // 验证空状态
        if(count !== 0)
            $display("Error: Expected count 0, got %0d", count);
            
        // 测试用例3：同时读写
        $display("\n=== Test 3: Concurrent R/W ===");
        wen = 1;
        ren = 1;
        repeat(4) begin
            wdata = $random;
            @(posedge clk);
            #1;
            $display("Write: 0x%h | Read: 0x%h | Count: %0d", 
                    wdata, rdata, count);
        end
        wen = 0;
        ren = 0;
        
        // 测试用例4：边界条件测试
        $display("\n=== Test 4: Boundary cases ===");
        
        // 写满测试
        wen = 1;
        repeat(MAX_DATA+2) begin
            wdata = $urandom;
            @(posedge clk);
        end
        wen = 0;
        $display("Overflow count: %0d", count);
        
        // 读空测试
        ren = 1;
        repeat(MAX_DATA+2) @(posedge clk);
        ren = 0;
        $display("Underflow count: %0d", count);
        
        // 结束仿真
        #100;
        $display("\nTestbench completed");
        $finish;
    end
    
    // 波形记录（可选）
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
    end
endmodule
```
以下是对提供的 Verilog 测试平台代码的逐步解析和说明：

---

#### **模块定义与信号声明**
```verilog
module fifo_tb;
    parameter MAX_DATA = 4;       // 测试深度设为4，便于快速验证
    localparam AWIDTH = $clog2(MAX_DATA); // AWIDTH=2 (2^2=4)
    
    // 输入信号
    reg clk, rst;
    reg wen, ren;
    reg [7:0] wdata;
    
    // 输出信号
    wire [7:0] rdata;
    wire [AWIDTH:0] count;        // 计数器位宽=3 (0~4)
    
    // 实例化被测FIFO
    fifo #(.MAX_DATA(MAX_DATA)) dut (...);
```
- **设计简化**：将 FIFO 深度设为 4，加速测试并更容易观察边界条件。
- **信号映射**：测试平台的输入/输出信号与 FIFO 模块直接对接。

---

### **2. 时钟生成**
```verilog
initial clk = 0;
always #5 clk = ~clk;  // 周期10ns，占空比50%
```
- 生成周期为 10ns 的时钟信号，用于驱动同步逻辑。

---

### **3. 主测试流程**
#### **初始化与复位**
```verilog
initial begin
    wen = 0; ren = 0; wdata = 0; rst = 1;
    #15 rst = 0;  // 15ns后释放复位
end
```
- 初始状态：所有控制信号置零，复位信号 (`rst`) 有效。
- 复位释放：15ns 后 `rst` 置零，确保复位信号覆盖至少一个时钟周期。

---

### **4. 测试用例详解**
#### **测试用例1：基本写操作**
```verilog
$display("\n=== Test 1: Basic write ===");
wen = 1;
repeat(MAX_DATA) begin
    wdata = $random;  // 生成随机数据
    @(posedge clk);   // 等待时钟上升沿
    #1;               // 等待信号稳定
    $display("Write: 0x%h | Count: %0d", wdata, count);
end
wen = 0;
```
- **操作**：连续写入 4 次随机数据。
- **检查点**：
  - 每次写入后计数器 `count` 应递增。
  - 写入完成后 `count` 应等于 4，表示 FIFO 满。

#### **测试用例2：基本读操作**
```verilog
$display("\n=== Test 2: Basic read ===");
ren = 1;
repeat(MAX_DATA) begin
    @(posedge clk);
    #1;
    $display("Read: 0x%h | Count: %0d", rdata, count);
end
ren = 0;
```
- **操作**：连续读取 4 次数据。
- **检查点**：
  - 每次读取后计数器 `count` 应递减。
  - 读取完成后 `count` 应等于 0，表示 FIFO 空。

#### **测试用例3：同时读写**
```verilog
$display("\n=== Test 3: Concurrent R/W ===");
wen = 1; ren = 1;
repeat(4) begin
    wdata = $random;
    @(posedge clk);
    #1;
    $display("Write: 0x%h | Read: 0x%h | Count: %0d", wdata, rdata, count);
end
```
- **操作**：同时进行 4 次写和读。
- **检查点**：
  - 计数器 `count` 应保持不变（读写操作抵消）。
  - 读取的数据应比写入的数据滞后一个周期（同步 FIFO 特性）。

#### **测试用例4：边界条件测试**
```verilog
$display("\n=== Test 4: Boundary cases ===");

// 写满测试（尝试写入6次，超过容量）
wen = 1;
repeat(MAX_DATA+2) begin
    wdata = $urandom;
    @(posedge clk);
end
wen = 0;
$display("Overflow count: %0d", count);  // 预期count=6

// 读空测试（尝试读取6次，超过容量）
ren = 1;
repeat(MAX_DATA+2) @(posedge clk);
ren = 0;
$display("Underflow count: %0d", count); // 预期count=7（3位无符号数）
```
- **操作**：故意触发溢出（写满后继续写）和下溢（读空后继续读）。
- **检查点**：
  - **溢出**：`count` 超过 `MAX_DATA`（设计缺陷，需后续修复）。
  - **下溢**：`count` 下溢为最大值（如 7），导致逻辑错误。

---

### **5. 波形记录与仿真结束**
```verilog
initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, fifo_tb);  // 记录所有信号波形
end

#100;
$display("\nTestbench completed");
$finish;
```
- 使用 `$dumpvars` 生成波形文件 (`fifo.vcd`)，便于使用 GTKWave 等工具调试。
- 仿真结束后打印完成信息并终止。

---

该测试平台覆盖了 FIFO 的基本功能，包括正常读写、并发操作和边界条件，但需进一步完善自动检查机制以提升验证效率。通过波形分析和关键测试用例，可清晰暴露设计中的缺陷（如无空满保护），为后续修复提供依据。

**iverilog仿真结果**  
![fifo](img3/fifo.png)

虽然开源的 `read_verilog` 前端在处理有效的 Verilog 输入时通常表现良好，但它提供的错误处理和报告功能并不完善。因此，在运行 Yosys 之前，强烈建议使用诸如 `verilator` 这样的外部工具。我们可以通过调用 `verilator --lint-only fifo.v` 来快速检查设计的 Verilog 语法。如果没有任何的语法错误，命令窗口就不会有任何的错误信息输出。

### 加载设计

让我们将设计加载到 Yosys 中。在命令行中，我们可以调用 `yosys fifo.v`。这将打开一个交互式的 Yosys shell 会话，并立即解析 `fifo.v` 中的代码，将其转换为抽象语法树（AST）。如果您对此过程感兴趣，可以在文档《Verilog 和 AST 前端》中找到更多信息。现在，我们只需知道这样做是为了简化设计的进一步处理。您应该会看到类似以下内容：

```bash
yosys fifo.v

 /----------------------------------------------------------------------------\
 |                                                                            |
 |  yosys -- Yosys Open SYnthesis Suite                                       |
 |                                                                            |
 |  Copyright (C) 2012 - 2020  Claire Xenia Wolf <claire@yosyshq.com>         |
 |                                                                            |
 |  Permission to use, copy, modify, and/or distribute this software for any  |
 |  purpose with or without fee is hereby granted, provided that the above    |
 |  copyright notice and this permission notice appear in all copies.         |
 |                                                                            |
 |  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  |
 |  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          |
 |  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   |
 |  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    |
 |  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     |
 |  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   |
 |  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            |
 |                                                                            |
 \----------------------------------------------------------------------------/

 Yosys 0.33 (git sha1 2584903a060)


-- Parsing `fifo.v' using frontend ` -vlog2k' --

1. Executing Verilog-2005 frontend: fifo.v
Parsing Verilog input from `fifo.v' to AST representation.
Storing AST representation for module `$abstract\addr_gen'.
Storing AST representation for module `$abstract\fifo'.
Successfully finished Verilog frontend.

yosys> 

```

### 细化

现在我们已经进入了交互式 shell，可以直接调用 Yosys 命令。我们的最终目标是调用 `synth_ice40 -top fifo`，但现在我们可以单独运行每个命令，以便更好地理解每个部分在流程中的作用。我们还将从一个单独的模块 `addr_gen` 开始。

在 `synth_ice40` 的帮助输出底部是该脚本调用的完整命令列表。让我们从标记为 `begin` 的部分开始：

**代码清单 2**  
`begin` 部分

```bash
read_verilog -D ICE40_HX -lib -specify +/ice40/cells_sim.v
yosys> read_verilog -D ICE40_HX -lib -specify +/ice40/cells_sim.v

2. Executing Verilog-2005 frontend: /usr/bin/../share/yosys/ice40/cells_sim.v
Parsing Verilog input from `/usr/bin/../share/yosys/ice40/cells_sim.v' to AST representation.
Generating RTLIL representation for module `\SB_IO'.
Generating RTLIL representation for module `\SB_GB_IO'.
Generating RTLIL representation for module `\SB_GB'.
Generating RTLIL representation for module `\SB_LUT4'.
Generating RTLIL representation for module `\SB_CARRY'.
Generating RTLIL representation for module `\SB_DFF'.
Generating RTLIL representation for module `\SB_DFFE'.
Generating RTLIL representation for module `\SB_DFFSR'.
Generating RTLIL representation for module `\SB_DFFR'.
Generating RTLIL representation for module `\SB_DFFSS'.
Generating RTLIL representation for module `\SB_DFFS'.
Generating RTLIL representation for module `\SB_DFFESR'.
Generating RTLIL representation for module `\SB_DFFER'.
Generating RTLIL representation for module `\SB_DFFESS'.
Generating RTLIL representation for module `\SB_DFFES'.
Generating RTLIL representation for module `\SB_DFFN'.
Generating RTLIL representation for module `\SB_DFFNE'.
Generating RTLIL representation for module `\SB_DFFNSR'.
Generating RTLIL representation for module `\SB_DFFNR'.
Generating RTLIL representation for module `\SB_DFFNSS'.
Generating RTLIL representation for module `\SB_DFFNS'.
Generating RTLIL representation for module `\SB_DFFNESR'.
Generating RTLIL representation for module `\SB_DFFNER'.
Generating RTLIL representation for module `\SB_DFFNESS'.
Generating RTLIL representation for module `\SB_DFFNES'.
Generating RTLIL representation for module `\SB_RAM40_4K'.
Generating RTLIL representation for module `\SB_RAM40_4KNR'.
Generating RTLIL representation for module `\SB_RAM40_4KNW'.
Generating RTLIL representation for module `\SB_RAM40_4KNRNW'.
Generating RTLIL representation for module `\ICESTORM_LC'.
Generating RTLIL representation for module `\SB_PLL40_CORE'.
Generating RTLIL representation for module `\SB_PLL40_PAD'.
Generating RTLIL representation for module `\SB_PLL40_2_PAD'.
Generating RTLIL representation for module `\SB_PLL40_2F_CORE'.
Generating RTLIL representation for module `\SB_PLL40_2F_PAD'.
Generating RTLIL representation for module `\SB_WARMBOOT'.
Generating RTLIL representation for module `\SB_SPRAM256KA'.
Generating RTLIL representation for module `\SB_HFOSC'.
Generating RTLIL representation for module `\SB_LFOSC'.
Generating RTLIL representation for module `\SB_RGBA_DRV'.
Generating RTLIL representation for module `\SB_LED_DRV_CUR'.
Generating RTLIL representation for module `\SB_RGB_DRV'.
Generating RTLIL representation for module `\SB_I2C'.
Generating RTLIL representation for module `\SB_SPI'.
Generating RTLIL representation for module `\SB_LEDDA_IP'.
Generating RTLIL representation for module `\SB_FILTER_50NS'.
Generating RTLIL representation for module `\SB_IO_I3C'.
Generating RTLIL representation for module `\SB_IO_OD'.
Generating RTLIL representation for module `\SB_MAC16'.
Generating RTLIL representation for module `\ICESTORM_RAM'.
Successfully finished Verilog frontend.
```

```bash
yosys> hierarchy -check -top fifo

5. Executing HIERARCHY pass (managing design hierarchy).

6. Executing AST frontend in derive mode using pre-parsed AST for module `\fifo'.
Generating RTLIL representation for module `\fifo'.

6.1. Analyzing design hierarchy..
Top module:  \fifo
Parameter \MAX_DATA = 256

6.2. Executing AST frontend in derive mode using pre-parsed AST for module `\addr_gen'.
Parameter \MAX_DATA = 256
Generating RTLIL representation for module `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000'.
Parameter \MAX_DATA = 256
Found cached RTLIL representation for module `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000'.

6.3. Analyzing design hierarchy..
Top module:  \fifo
Used module:     $paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000

6.4. Analyzing design hierarchy..
Top module:  \fifo
Used module:     $paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000
Removing unused module `$abstract\fifo'.
Removing unused module `$abstract\addr_gen'.
Removed 2 unused modules.
```

```bash
yosys> proc

7. Executing PROC pass (convert processes to netlists).

7.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

7.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Marked 2 switch rules as full_case in process $proc$fifo.v:12$462 in module $paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.
Marked 2 switch rules as full_case in process $proc$fifo.v:62$454 in module fifo.
Marked 1 switch rules as full_case in process $proc$fifo.v:36$446 in module fifo.
Removed a total of 0 dead cases.

7.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 6 assignments to connections.

7.4. Executing PROC_INIT pass (extract init attributes).
Found init rule in `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:0$465'.
  Set init value: \addr = 8'00000000
Found init rule in `\fifo.$proc$fifo.v:0$461'.
  Set init value: \count = 9'000000000

7.5. Executing PROC_ARST pass (detect async resets in processes).
Found async reset \rst in `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:12$462'.
Found async reset \rst in `\fifo.$proc$fifo.v:62$454'.

7.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.
<suppressed ~5 debug messages>

7.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:0$465'.
Creating decoders for process `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:12$462'.
     1/1: $0\addr[7:0]
Creating decoders for process `\fifo.$proc$fifo.v:0$461'.
Creating decoders for process `\fifo.$proc$fifo.v:62$454'.
     1/1: $0\count[8:0]
Creating decoders for process `\fifo.$proc$fifo.v:36$446'.
     1/3: $1$memwr$\data$fifo.v:38$445_EN[7:0]$452
     2/3: $1$memwr$\data$fifo.v:38$445_DATA[7:0]$451
     3/3: $1$memwr$\data$fifo.v:38$445_ADDR[7:0]$450

7.8. Executing PROC_DLATCH pass (convert process syncs to latches).

7.9. Executing PROC_DFF pass (convert process syncs to FFs).
Creating register for signal `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.\addr' using process `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:12$462'.
  created $adff cell `$procdff$485' with positive edge clock and positive level reset.
Creating register for signal `\fifo.\count' using process `\fifo.$proc$fifo.v:62$454'.
  created $adff cell `$procdff$486' with positive edge clock and positive level reset.
Creating register for signal `\fifo.\rdata' using process `\fifo.$proc$fifo.v:36$446'.
  created $dff cell `$procdff$487' with positive edge clock.
Creating register for signal `\fifo.$memwr$\data$fifo.v:38$445_ADDR' using process `\fifo.$proc$fifo.v:36$446'.
  created $dff cell `$procdff$488' with positive edge clock.
Creating register for signal `\fifo.$memwr$\data$fifo.v:38$445_DATA' using process `\fifo.$proc$fifo.v:36$446'.
  created $dff cell `$procdff$489' with positive edge clock.
Creating register for signal `\fifo.$memwr$\data$fifo.v:38$445_EN' using process `\fifo.$proc$fifo.v:36$446'.
  created $dff cell `$procdff$490' with positive edge clock.

7.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

7.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Removing empty process `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:0$465'.
Found and cleaned up 2 empty switches in `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:12$462'.
Removing empty process `$paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.$proc$fifo.v:12$462'.
Removing empty process `fifo.$proc$fifo.v:0$461'.
Found and cleaned up 2 empty switches in `\fifo.$proc$fifo.v:62$454'.
Removing empty process `fifo.$proc$fifo.v:62$454'.
Found and cleaned up 1 empty switch in `\fifo.$proc$fifo.v:36$446'.
Removing empty process `fifo.$proc$fifo.v:36$446'.
Cleaned up 5 empty switches.

7.12. Executing OPT_EXPR pass (perform const folding).
Optimizing module $paramod\addr_gen\MAX_DATA=s32'00000000000000000000000100000000.
Optimizing module fifo.
```

`read_verilog -D ICE40_HX -lib -specify +/ice40/cells_sim.v` 加载了 iCE40 的单元模型，这使我们能够在设计中包含平台特定的 IP 块。PLL 是一个常见的例子，我们可能需要直接引用 `SB_PLL40_CORE`，而不是依赖后续的映射过程。由于我们的简单设计没有使用这些 IP 块，我们可以暂时跳过这个命令。不过，一旦我们开始映射到硬件，仍然需要加载这些单元模型。

**注意**

`+/` 是对 Yosys 共享目录的动态引用。默认情况下，这是 `/usr/local/share/yosys`。如果使用从源代码目录本地构建的 Yosys 版本，这将是同一目录中的 `share` 文件夹。

最后输入`exit`退出Yosys程序。

### `addr_gen` 模块

由于我们刚刚开始，让我们从 `hierarchy -top addr_gen` 开始。该命令声明顶层模块是 `addr_gen`，其他所有内容都可以丢弃。

**代码清单 3**  
`addr_gen.v` 模块源代码

```verilog
module addr_gen 
#(  parameter MAX_DATA=256,
	localparam AWIDTH = $clog2(MAX_DATA)
) ( input en, clk, rst,
	output reg [AWIDTH-1:0] addr
);
	initial addr = 0;

	// 异步复位
	// 当使能时递增地址
	always @(posedge clk or posedge rst)
		if (rst)
			addr <= 0;
		else if (en) begin
			if ({'0, addr} == MAX_DATA-1)
				addr <= 0;
			else
				addr <= addr + 1;
		end
endmodule //addr_gen
```
以下是对所提供Verilog代码的详细解析：

---

#### 模块定义与参数
```verilog
module addr_gen 
#(  parameter MAX_DATA=256,
    localparam AWIDTH = $clog2(MAX_DATA)
) (
    input en, clk, rst,
    output reg [AWIDTH-1:0] addr
);
```
- **功能**：该模块用于生成循环递增的地址。
- **参数**：
  - `MAX_DATA`：地址范围的最大值，默认为256。
  - `AWIDTH`：地址位宽，由`$clog2(MAX_DATA)`自动计算得出。若`MAX_DATA=256`，则`AWIDTH=8`。
- **端口**：
  - `en`：使能信号，控制地址递增。
  - `clk`：时钟信号。
  - `rst`：异步复位信号。
  - `addr`：输出地址，位宽为`AWIDTH`。

---

#### 初始值设置
```verilog
initial addr = 0;
```
- **行为**：在仿真开始时，将`addr`初始化为0。
- **注意**：`initial`语句在综合中可能被忽略，实际硬件行为由复位逻辑决定。

---

#### 核心逻辑
```verilog
always @(posedge clk or posedge rst)
    if (rst)
        addr <= 0;
    else if (en) begin
        if ({'0, addr} == MAX_DATA-1)
            addr <= 0;
        else
            addr <= addr + 1;
    end
```
- **异步复位**：当`rst`为高电平时，立即将`addr`清零。
- **递增逻辑**：
  - 在时钟上升沿，若`en`有效且未复位，则执行以下操作：
    1. **循环检查**：比较当前地址`addr`是否等于`MAX_DATA-1`。
       - `{'0, addr}`：将`addr`高位补零，扩展至与`MAX_DATA-1`相同位宽，确保比较正确性。
    2. **归零或递增**：
       - 若相等，`addr`归零，实现循环。
       - 否则，`addr`加1。

---

#### 关键设计点
1. **地址位宽计算**：
   - `$clog2(MAX_DATA)`确保地址位宽最小化。例如：
     - `MAX_DATA=1000` → `AWIDTH=10`（因`2^10=1024 ≥ 1000`）。
     - `MAX_DATA=256` → `AWIDTH=8`。

2. **循环行为**：
   - 地址在`0`到`MAX_DATA-1`之间循环，严格限制在用户定义范围内。
   - 例：若`MAX_DATA=200`，地址范围为`0~199`，到达199后归零。

3. **复位与初始化**：
   - 异步复位确保立即响应复位信号。
   - `initial`语句仅用于仿真，实际硬件依赖复位信号初始化。

4. **位宽扩展**：
   - `{'0, addr}`显式扩展位宽，避免比较时的隐式符号扩展问题，增强代码健壮性。

---

#### 潜在问题与改进
1. **`MAX_DATA`非2的幂**：
   - 若`MAX_DATA=300`，`AWIDTH=9`（`2^9=512`），地址最大值为`299`，此时逻辑正确。
   - 但若`en`持续有效且外部未限制，地址仍会从`299`归零，无越界风险。

2. **综合与初始化**：
   - 实际硬件中，建议依赖复位信号而非`initial`语句初始化寄存器。

3. **位宽优化**：
   - `{'0, addr}`可简化为`addr`，因Verilog默认无符号数高位补零比较，但显式扩展更清晰。

---

#### 应用场景
- **存储器访问**：循环遍历存储器的连续地址。
- **状态机控制**：生成周期性状态或索引。
- **数据流管理**：控制缓冲区的读写指针。

---

#### 示例波形
- **复位阶段**：`rst=1` → `addr=0`。
- **递增阶段**：`rst=0, en=1` → `addr`每周期加1。
- **循环归零**：当`addr=MAX_DATA-1`时，下一周期归零。

---
### 测试流程

**代码清单 4**  
`tb_addr_gen.v` 模块testbench

```verilog
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
```
以下是代码的详细解析：

### 模块结构
```verilog
`timescale 1ns/1ps
module tb_addr_gen;
    reg clk = 0;
    reg rst, en;
    wire [7:0] addr;
    
    addr_gen #(.MAX_DATA(256)) uut (.en(en), .clk(clk), .rst(rst), .addr(addr));
    
    always #5 clk = ~clk;  // 10ns周期时钟
```
- **时钟生成**：通过`always`块生成周期为10ns（5ns高电平+5ns低电平）的时钟信号。
- **实例化被测模块**：`addr_gen`模块被实例化为`uut`，设置最大数据`MAX_DATA`为256，对应8位地址线。

---

#### 1. 初始化
```verilog
$dumpfile("tb_addr_gen.vcd");
$dumpvars(0, tb_addr_gen);
rst = 1; en = 0;
#20 rst = 0;  // 复位20ns后释放
```
- 初始化波形记录文件和信号。
- 复位信号`rst`保持高电平20ns后释放，确保模块初始状态正确。

---

#### 2. 测试1：`en=0`时地址不变
```verilog
en = 0;
repeat(2) @(posedge clk);
if (addr !== 8'd0) $error("Test1 Failed");
```
- 使能信号`en`置0，等待2个时钟周期。
- 验证地址`addr`保持初始值0，确认模块在非使能状态下不递增。

---

#### 3. 测试2：地址递增至255后回绕
```verilog
en = 1;
expected = 0;
for (i=0; i<256; i=i+1) begin
    @(posedge clk);
    #1;  // 等待信号稳定
    if (addr !== expected) $error(...);
    expected = (expected==255) ? 0 : expected+1;
}
```
- 使能信号`en`置1，循环256次，每次检查地址是否正确递增。
- `expected`变量跟踪预期值，达到255后归零，验证地址回绕功能。

---

#### 4. 测试3：回绕后继续递增
```verilog
@(posedge clk);
#1;
if (addr !== 8'd1) $error(...);
```
- 在测试2结束后，下一个时钟周期检查地址是否从0递增到1，确认回绕逻辑正确。

---

#### 5. 测试4：再次验证`en=0`时地址不变
```verilog
en = 0;
repeat(2) @(posedge clk);
if (addr !== 8'd1) $error(...);
```
- 再次禁用使能信号，等待2个周期后地址应保持1，确保模块在非使能状态下冻结地址。

---

#### 6. 测试5：异步复位测试
```verilog
en = 1;
@(negedge clk);  // 时钟低电平时触发复位
rst = 1;
#1;
if (addr !== 8'd0) $error(...);  // 立即检查复位生效
@(posedge clk);
#1;
if (addr !== 8'd0) $error(...);  // 时钟上升沿后保持0
rst = 0;
```
- 在时钟低电平时激活复位，验证地址立即归零（异步复位特性）。
- 下一个上升沿后地址仍为0，确认复位释放后模块从0开始。

---

### 关键设计要点
1. **复位机制**：测试5验证了复位是异步的，立即生效且独立于时钟。
2. **使能控制**：通过`en`信号控制地址递增，确保模块仅在使能时工作。
3. **边界条件**：测试2覆盖了地址从0到255的全范围，验证回绕逻辑。
4. **时序检查**：使用`#1`延迟避开时序竞争，确保采样时信号稳定。

---

### 潜在改进点
- **随机化测试**：可加入随机化的`en`和`rst`信号，增强测试覆盖率。
- **错误注入**：模拟极端情况（如复位在地址255时触发）。
- **代码复用**：将重复的测试逻辑封装为任务或函数，提高可维护性。

此测试平台全面验证了`addr_gen`模块的核心功能，包括正常递增、回绕、使能控制和异步复位，确保了模块的可靠性。


**仿真结果**

![addr_gen](img3/addr_gen_sim.png)


首先输入命令：`yosys addr_gen.v`，可以得到下面的结果
```bash

 /----------------------------------------------------------------------------\
 |                                                                            |
 |  yosys -- Yosys Open SYnthesis Suite                                       |
 |                                                                            |
 |  Copyright (C) 2012 - 2020  Claire Xenia Wolf <claire@yosyshq.com>         |
 |                                                                            |
 |  Permission to use, copy, modify, and/or distribute this software for any  |
 |  purpose with or without fee is hereby granted, provided that the above    |
 |  copyright notice and this permission notice appear in all copies.         |
 |                                                                            |
 |  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  |
 |  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          |
 |  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   |
 |  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    |
 |  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     |
 |  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   |
 |  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            |
 |                                                                            |
 \----------------------------------------------------------------------------/

 Yosys 0.33 (git sha1 2584903a060)


-- Parsing `addr_gen.v' using frontend ` -vlog2k' --

1. Executing Verilog-2005 frontend: addr_gen.v
Parsing Verilog input from `addr_gen.v' to AST representation.
Storing AST representation for module `$abstract\addr_gen'.
Successfully finished Verilog frontend.
```

**注意**

`hierarchy` 应该始终是在设计读取后调用的第一个命令。通过指定顶层模块，`hierarchy` 还会在其上设置 `(* top *)` 属性。其他需要知道哪个模块是顶层的命令会使用此属性。

**代码清单 4**  
`hierarchy -top addr_gen` 输出
```
yosys> hierarchy -top addr_gen

2. Executing HIERARCHY pass (managing design hierarchy).

3. Executing AST frontend in derive mode using pre-parsed AST for module `\addr_gen'.
Generating RTLIL representation for module `\addr_gen'.

3.1. Analyzing design hierarchy..
Top module:  \addr_gen

3.2. Analyzing design hierarchy..
Top module:  \addr_gen
Removing unused module `$abstract\addr_gen'.
Removed 1 unused modules.
```

现在，输入命令`show`，我们的 `addr_gen` 电路看起来像这样：
输入命令
```bash
show
```
![addr_gen](img3/addr_gen.png)

### 简单操作的处理

在 `addr_gen` 模块的源代码中，像 `addr + 1` 和 `addr == MAX_DATA-1` 这样的简单操作可以从 `always @` 块中提取出来。这为我们提供了高亮的 `$add` 和 `$eq` 单元。然而，控制逻辑（如 `if .. else`）和存储元素（如 `addr <= 0`）则不那么直接。这些内容被放入“进程”中，在原理图中显示为 `PROC`。注意第二行引用了对应 `always @` 块的起始/结束行号。如果是 `initial` 块，我们会看到 `PROC` 引用第 0 行。

为了处理这些内容，我们现在引入下一个命令：`proc` —— 将进程转换为网表。`proc` 是一个类似于 `synth_ice40` 的宏命令。它不会直接修改设计，而是调用一系列其他命令。在 `proc` 的情况下，这些子命令将进程的行为逻辑转换为多路复用器和寄存器。让我们看看运行它时会发生什么。现在，我们将调用 `proc -noopt` 以防止一些通常会自动发生的优化。

### 运行 `proc -noopt`

当我们运行 `proc -noopt` 时，设计中的进程会被转换为更底层的逻辑单元。具体来说：

1. **控制逻辑**：`if .. else` 语句会被转换为多路复用器（`$mux` 单元）。
2. **存储元素**：寄存器赋值（如 `addr <= 0`）会被转换为触发器（`$dff` 或 `$adff` 单元）。

在运行 `proc -noopt` 后，设计中的 `always @` 块会被分解为多个基本单元。例如：

- `if (rst)` 会被转换为一个多路复用器，用于选择复位值或正常操作值。
- `addr <= addr + 1` 会被转换为一个加法器（`$add` 单元）和一个触发器（`$dff` 单元）。

### 示例输出

运行 `proc -noopt` 后，您可能会看到类似以下的输出：

```bash
yosys> proc -noopt

5. Executing PROC pass (convert processes to netlists).

5.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

5.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Marked 2 switch rules as full_case in process $proc$addr_gen.v:11$1 in module addr_gen.
Removed a total of 0 dead cases.

5.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 1 assignment to connection.

5.4. Executing PROC_INIT pass (extract init attributes).
Found init rule in `\addr_gen.$proc$addr_gen.v:0$4'.
  Set init value: \addr = 8'00000000

5.5. Executing PROC_ARST pass (detect async resets in processes).
Found async reset \rst in `\addr_gen.$proc$addr_gen.v:11$1'.

5.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.
<suppressed ~2 debug messages>

5.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `\addr_gen.$proc$addr_gen.v:0$4'.
Creating decoders for process `\addr_gen.$proc$addr_gen.v:11$1'.
     1/1: $0\addr[7:0]

5.8. Executing PROC_DLATCH pass (convert process syncs to latches).

5.9. Executing PROC_DFF pass (convert process syncs to FFs).
Creating register for signal `\addr_gen.\addr' using process `\addr_gen.$proc$addr_gen.v:11$1'.
  created $adff cell `$procdff$10' with positive edge clock and positive level reset.

5.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

5.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Removing empty process `addr_gen.$proc$addr_gen.v:0$4'.
Found and cleaned up 2 empty switches in `\addr_gen.$proc$addr_gen.v:11$1'.
Removing empty process `addr_gen.$proc$addr_gen.v:11$1'.
Cleaned up 2 empty switches.
```

### 原理图变化
再次输入命令`show`可以得到新的原理图：
![addr_gen](img3/addr_gen2.png)
在原理图中，您会看到以下变化：

- **多路复用器**：`if .. else` 逻辑被转换为 `$mux` 单元。
- **触发器**：寄存器赋值被转换为 `$adff` 单元。
- **加法器**：`addr + 1` 被转换为 `$add` 单元。


### 处理 `proc -noopt` 后的设计

在运行 `proc -noopt` 之后，我们的设计中新增了一些单元，这些单元已被高亮显示。具体来说：

- **`if` 语句**：现在被建模为 `$mux` 单元。
- **寄存器**：使用 `$adff` 单元来实现。

如果我们查看终端输出，还可以看到所有不同的 `proc_*` 命令被调用。我们将在**转换进程块**部分更详细地探讨这些命令。

### 浮空线的处理

在 `proc -noopt` 之后的 `addr_gen` 模块的左上角，我们有一个浮空的线。这条线是由 `addr` 线的初始赋值 `0` 生成的。然而，这个初始赋值是不可综合的，因此在生成物理硬件之前需要清理。

### 清理和优化

在运行 `proc -noopt` 后，设计可能会包含一些冗余的逻辑或未连接的线。为了清理这些内容，我们可以运行以下命令：

```bash
yosys> opt_expr; clean

7. Executing OPT_EXPR pass (perform const folding).
Optimizing module addr_gen.
Removed 0 unused cells and 4 unused wire
```


- **`opt_expr`**：执行常量折叠和简单的表达式优化。
- **`clean`**：移除未使用的单元和线。

通过运行 `proc -noopt`，我们将设计中的行为逻辑转换为底层的逻辑单元，如多路复用器和触发器。这为后续的优化和硬件映射奠定了基础。接下来，我们可以通过 `opt_expr` 和 `clean` 进一步优化和清理设计。

**注意**：`proc` 是综合流程中的一个关键步骤，它将高级的行为描述转换为可综合的低级网表。理解这一过程对于掌握 FPGA 综合流程非常重要。

#### `opt_expr` 的作用
- **常量折叠**：将常量表达式计算为单个值。
- **简单表达式优化**：简化逻辑表达式，例如 `a + 0` 会被优化为 `a`。

#### `clean` 的作用
- **移除未使用的单元和线**：清理设计中未连接或未使用的部分，以减少冗余。

### 原理图变化
继续输入命令`show`可以得到新的原理图
![addr_gen](img3/addr_gen3.png)
在清理和优化之后，原理图会发生以下变化：

- **浮空线被移除**：初始赋值生成的浮空线被清理。
- **逻辑简化**：`opt_expr` 可能会将一些复杂的逻辑表达式简化为更简单的形式。

### 常量值的优化

在运行 `opt_expr` 后，您可能会注意到高亮的 `$eq` 单元的输入 `255` 已更改为 `8'11111111`。常量值以 `<bit_width>'<bits>` 的格式呈现，其中 `bit_width` 表示位宽，`bits` 表示二进制值。对于 32 位值，通常使用十进制数表示。这里的 `8'11111111` 表示一个 8 位宽的二进制值，其十进制等效值为 255。

### 位宽减少的原因

这种变化是 `opt_expr` 执行**常量折叠**和**简单表达式重写**的副作用。具体来说：

1. **常量折叠**：`opt_expr` 会计算常量表达式，并将其替换为计算结果。例如，`255` 是一个常量，因此它被直接替换为其二进制表示 `8'11111111`。
2. **位宽优化**：`opt_expr` 还会分析信号的位宽，并尝试减少不必要的位宽。在这个例子中，`255` 可以用 8 位表示（因为 \(2^8 = 256\)），因此 `opt_expr` 将其从 32 位减少到 8 位。

### 为什么位宽减少很重要？

减少位宽可以带来以下好处：
- **资源节省**：更小的位宽意味着更少的逻辑单元和布线资源被占用。
- **性能提升**：较小的位宽通常意味着更快的操作，因为硬件需要处理的数据量减少了。
- **功耗降低**：减少位宽可以减少动态功耗，因为更少的信号需要切换。

### 示例

假设我们有以下 Verilog 代码：

```verilog
reg [31:0] addr;
always @(posedge clk) begin
    if (addr == 255) begin
        // Do something
    end
end
```

在运行 `opt_expr` 后，`addr == 255` 会被优化为 `addr == 8'11111111`，因为 `255` 可以用 8 位表示。

### 进一步阅读

如果您对 `opt_expr` 的更多细节感兴趣，可以参考以下部分：
- **优化过程**：详细介绍了 Yosys 中的各种优化步骤。
- **`opt_expr` 部分**：专门讨论了常量折叠和表达式重写的机制。

### 总结

通过运行 `opt_expr`，Yosys 能够优化设计中的常量值和表达式，减少不必要的位宽并简化逻辑。这不仅提高了设计的效率，还为后续的综合和硬件映射步骤奠定了基础。

**注意**：在设计流程中，理解这些优化步骤的作用非常重要。它们可以帮助您更好地控制设计的资源利用率和性能。