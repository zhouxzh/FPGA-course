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
`addr_gen` 模块源代码

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