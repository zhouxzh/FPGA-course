---
title: "第2讲：开源Verilog仿真工具"
author: [周贤中]
date: 2025-03-30
subject: "Markdown"
keywords: [FPGA, 系统设计]
lang: "zh-cn"
...

---

## 开源verilog仿真工具介绍

### Icarus Verilog
<!-- ![GitHub Stars](https://img.shields.io/github/stars/steveicarus/iverilog) -->

#### 核心架构
```mermaid architecture.mmd
flowchart LR
    Verilog[*.v文件] --> iverilog --> vvp[仿真引擎] --> VCD[波形文件] --> GTKWave
```

#### 关键特性

```bash debug_flow.sh
 $ dumpfile()  # 波形文件定义
 $ dumpvars()  # 信号抓取配置
 $ display()   # 实时打印调试
```

---

### Verilator
![GitHub Stars](https://img.shields.io/github/stagename/verilator/verilator)

---

#### 创新架构

```c++ verilator_arch.cpp
// 将Verilog转换为优化的C++模型
Verilated::traceEverOn(true);
Vmymodule* top = new Vmymodule;

while (vtime < 100ns) {
    top->clock = !top->clock;
    top->eval();
    tfp->dump(vtime);
}
```

#### 性能对比
| 测试项         | Icarus | Verilator | 提升幅度 |
|---------------|--------|-----------|---------|
| AES128加密     | 12.3s  | 0.8s      | 15x     |
| DDR3控制器     | 58.4s  | 3.2s      | 18x     |
| RISC-V核心     | 214s   | 14.7s     | 14.5x   |

---

### 工具链对比分析

#### 特性对比表
| 特性                | Icarus Verilog | Verilator   |
|---------------------|----------------|-------------|
| 编译方式            | 解释执行       | C++转换     |
| 波形调试            | 完善           | 有限        |
| 覆盖率分析          | 不支持         | 支持        |
| 多语言接口          | VPI            | SystemC/C++ |
| IDE集成            | GTKWave        | CLI/GUI     |

#### 适用场景建议
- **快速原型验证** → Icarus Verilog
- **复杂系统仿真** → Verilator
- **混合语言验证** → Verilator + C++

---

#### 波形分析优化
```python wave_analysis.py
import pygtkwave
with pygtkwave.GTKWave() as gw:
    gw.load('wave.vcd')
    gw.zoom_full()
    gw.save('capture.png')
```

---

### 生态环境

#### 插件扩展
| 插件名称         | 功能                   | 平台支持    |
|------------------|------------------------|------------|
| Vbuddy           | 外设模拟               | Icarus     |
| Cocotb           | Python测试框架         | Both       |
| FST              | 快速波形格式           | Verilator  |

#### 学习资源
- [Icarus用户手册](http://iverilog.icarus.com/usr_guide.pdf)
- [Verilator官方文档](https://verilator.org/guide/latest/)
- 在线仿真平台：[EDA Playground](https://www.edaplayground.com)

## iverilog+GTKWave使用教程

若您仅需验证Verilog文件的语法正确性并进行基础时序仿真，Icarus Verilog（iverilog）是最轻量高效的解决方案之一。相较于主流FPGA集成开发环境（IDE）动辄数GB的安装体积，其Windows版安装包仅18MB（最新v12版），同时提供Linux/macOS原生支持。作为开源编译器（GPLv2协议），它兼具以下优势：

1. **全平台支持** - 完美兼容Windows/Linux/macOS操作系统
2. **极简工作流** - 终端命令直达编译/仿真全流程
3. **EDA兼容性** - 支持标准Verilog-2005语法及部分SystemVerilog扩展

---

### Icarus Verilog介绍
Icarus Verilog（iverilog）是由Stephen Williams开发的轻量级开源Verilog编译器，基于C++实现并遵循**GNU GPLv2协议**。其核心功能链包含：

```bash installation.sh
# Linux安装示例（Debian系）
sudo apt-get install iverilog gtkwave
```
---

**架构特性**：
1. **跨平台编译** - 支持Windows(MSVC/MinGW)/Linux/macOS三端开发
2. **EDA工具链集成** 
   - 内置波形生成器（通过`vvp`命令行工具）
   - GTKWave捆绑实现波形可视化
3. **多语言互操作** - 支持Verilog/VHDL混合仿真与格式转换

---

典型工作流示例：
```verilog testbench.v
module tb;
  reg clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
endmodule
```

```bash simulation.sh
iverilog -o wave testbench.v           # 编译生成波形文件
vvp wave                        # 执行仿真                
gtkwave wave.vcd                # 开启波形分析
```

---

工具链优势对比表：
| 特性            | Icarus Verilog | 商业IDE       |
|----------------|----------------|-------------|
| 安装体积         | <20MB          | 2GB+         |
| 启动速度         | 0.3s           | 15s+         |
| 标准支持         | IEEE1364-2005  | SystemVerilog|

### Icarus Verilog 环境部署

#### 核心组件说明

- **版本信息**：当前稳定版为 v12 (2022)
- **依赖工具链**：  
  ```bash
   iverilog (主编译器)  
   vvp (仿真执行引擎)  
   gtkwave (波形可视化工具)
  ```

---

#### Windows 部署流程
```powershell windows_install.ps1
# 下载官方安装包（清华镜像）
$url = "https://mirrors.tuna.tsinghua.edu.cn/iverilog/v12/iverilog-v12-x64-setup.exe"
Invoke-WebRequest -Uri $url -OutFile iverilog_setup.exe

# 静默安装（默认路径 C:\iverilog）
Start-Process .\iverilog_setup.exe -ArgumentList "/S" -Wait

# 验证安装路径
where.exe iverilog
where.exe vvp
where.exe gtkwave
```

---

#### Linux 部署（以 Ubuntu 22.04 为例）
```bash linux_install.sh
# APT 源配置（推荐清华源）
sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 基础安装
sudo apt update && sudo apt install -y iverilog gtkwave

# 开发版安装（可选）
sudo add-apt-repository ppa:ppg/ppa
sudo apt install icarus-verilog-git
```

---

#### macOS 部署方案
```bash mac_install.sh
# Homebrew 方案（推荐）
brew tap oseng/os       # 添加第三方仓库
brew install icarus-verilog
brew install --cask gtkwave

# MacPorts 方案（备选）
sudo port install iverilog
sudo port install gtkwave
```

---

#### 环境验证

Windows/Linux/macOS 通用验证命令：
```bash env_check.sh
echo "版本信息：" && iverilog -v
echo "编译路径：" && which iverilog
echo "仿真引擎：" && which vvp
echo "波形工具：" && which gtkwave
```

---

> **疑难解答**：    
> - Ubuntu 源更新失败时尝试`sudo rm /var/lib/apt/lists/lock`  
> - Mac 安装出现权限问题使用`brew doctor`诊断
> - 出现动态库缺失时执行`sudo apt install libreadline-dev`

---

### 编译器核心参数详解

#### [-o] 输出文件参数

```verilog compile_command.v
# 通用编译命令模板
iverilog -o <output_file> <source_files>
```

| 使用场景       | 示例命令                      | 输出结果      |  
|---------------|-----------------------------|-------------|
| 默认参数       | `iverilog test.v`          | a.out       |
| 指定输出名     | `iverilog -o wave test.v` | wave        |

---

#### [-y] 模块路径声明

```verilog missing_module_error.v
// 典型模块未找到错误
Error: Unknown module type: mod_name
```

文件树结构示例：  
```filetree project_structure.tree
├── tb/
│   └── top_tb.v  
└── src/
    └── module.v
```

---

解决方案：  
```bash path_specification.sh
# 添加多个路径声明（支持通配符）
iverilog -y ./src -y ../lib/arithmetic -o wave top_tb.v
```

#### [-I] 头文件包含
```verilog include_example.v
`include "defines.vh"
```

---

跨平台路径声明技巧：  
```bash cross_platform.sh
# Windows路径
iverilog -I D:/project/headers
# Linux/Mac路径
iverilog -I /opt/verilog/includes
```

---

#### [-tvhdl] 语言转换
```bash conversion_script.sh
# Verilog转VHDL批处理脚本
iverilog -tvhdl -o ${filename}.vhd ${filename}.v
```

---

### 完整开发实例

#### 工程文件结构
```filetree led_project.tree
├── rtl/
│   └── led_demo.v        # 设计文件  
├── tb/
│   └── led_demo_tb.v     # 测试平台  
└── Makefile              # 自动化脚本
```

---

#### RTL代码例子
```verilog
// LED控制模块（十进制计数器触发）
module led_demo(
  input   wire    clk,    // 系统时钟（50MHz）
  input   wire    rst_n,  // 低电平复位信号
  output  reg     led     // LED输出
);

  reg [3:0] cnt;  // 4位计数器（计数范围0-10）

  // 时钟驱动计数器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 4'd0;
    end else begin
      cnt <= (cnt >= 4'd10) ? 4'd0 : cnt + 4'd1;
    end
  end

  // LED状态切换逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      led <= 1'b0;
    end else if (cnt == 4'd10) begin
      led <= ~led;
    end
  end

endmodule

```

---

#### testbench
```verilog
`timescale 1ns/1ps  // 时间精度设置

module led_demo_tb;

  // 时钟参数
  parameter CLK_PERIOD = 20;  // 50MHz时钟周期

  // 测试信号声明
  reg   clk_tb;
  reg   rst_n_tb;
  wire  led_tb;

  // 波形记录（Icarus专用）
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, led_demo_tb);
  end

  // 时钟生成（持续运行）
  initial begin
    clk_tb = 1'b0;
    forever #(CLK_PERIOD/2) clk_tb = ~clk_tb;
  end

  // 复位控制序列
  initial begin
    rst_n_tb = 1'b0;
    #(CLK_PERIOD*3) rst_n_tb = 1'b1;  // 3个周期后释放复位
    #(CLK_PERIOD*30) $finish;         // 运行30个周期后结束
  end

  // DUT实例化
  led_demo dut_inst (
    .clk   (clk_tb),
    .rst_n (rst_n_tb),
    .led   (led_tb)
  );

endmodule
```

---

#### 仿真数据生成流程
```bash simulation_flow.sh
# Step 1 - 编译检测
iverilog -y ./rtl -o wave ./tb/led_demo_tb.v

# Step 2 - 生成波形（支持格式扩展）
vvp -n wave -lxt2

# Step 3 - 波形分析（多格式兼容）
gtkwave wave.vcd wave.lxt
```

---

### VHDL协同工作流

#### 混合语言编译配置
```bash mixed_language.sh
# 启用SystemVerilog兼容模式
iverilog -g2012 -y vhdl_src -o mixed_design \
         file.vhd top.sv
```

---

### 自动化脚本配置

#### Windows批处理文件

```batch windows_run.bat
@echo off
set SRC_DIR=.\rtl
set TB_DIR=.\tb

iverilog -y %SRC_DIR% -o wave %TB_DIR%\*.v
vvp -n wave -lxt2
gtkwave wave.vcd
```

---

#### Linux/Mac Makefile模板

```makefile Makefile
# Verilog仿真自动化脚本
SIM_NAME = sim_out
SRC_DIR = ./rtl
TB_DIR = ./tb

.PHONY: all compile simulate view clean

all: compile simulate

compile:
	iverilog -o $(SIM_NAME) \
	-y $(SRC_DIR) \
	$(TB_DIR)/led_demo_tb.v

simulate:
	vvp -n $(SIM_NAME) -lxt2

view:
	gtkwave wave.vcd &

clean:
	rm -f $(SIM_NAME) *.vcd *.lxt
```

---

#### 仿真结果
![gtkwave](img2/gtkwave.png) 

---

### 生态与扩展

#### 硬件厂商支持列表
| 厂商       | 支持状态           | 配置命令示例               |  
|-----------|-------------------|-------------------------|
| Xilinx    | ISE兼容            | `-y $XILINX/verilog/src` |  
| Altera    | Quartus部分支持    | `-y $QUARTUS/eda/sim_lib`|
| Lattice   | Diamond完整支持    | `-y $DIAMOND/cae_library`|

---

### 扩展资源
[![GitHub Stars](https://img.shields.io/github/stars/steveicarus/iverilog?style=flat-square)](https://github.com/steveicarus/iverilog)  
[官方文档镜像](https://iverilog.icarus.com/docs) | [GTKWave手册](https://gtkwave.sourceforge.net/gtkwave.pdf)

---

## Verilator使用教程

### Verilator简介
Verilator 软件包将 Verilog和 SystemVerilog硬件描述语言（HDL）设计转换为 C++ 或 SystemC 模型，该模型在编译后可以执行。Verilator 不是传统的模拟器，而是一个编译器。

Verilator 通常按以下方式使用：

1. **Verilator 可执行文件**：使用类似于 GCC 或其他模拟器（如 Cadence Verilog-XL/NC-Verilog 或 Synopsys VCS）的参数调用 Verilator 可执行文件。Verilator 读取指定的 SystemVerilog 代码，进行代码检查，可选地添加覆盖率和波形跟踪支持，并将设计编译为源级多线程 C++ 或 SystemC “模型”。生成的模型的 C++ 或 SystemC 代码输出为 `.cpp` 和 `.h` 文件。这个过程被称为 “Verilating”，输出的是一个 “Verilated” 模型。

2. **用户编写的 C++ 包装文件**：为了进行模拟，需要一个用户编写的 C++ 包装文件，称为 “wrapper”。这个包装文件定义了 C++ 标准函数 `main()`，该函数将 Verilated 模型实例化为 C++/SystemC 对象。

3. **编译**：用户编写的 C++ 包装文件、Verilator 生成的文件、Verilator 提供的 “运行时库” 以及（如果适用）SystemC 库，使用 C++ 编译器编译，生成模拟可执行文件。

4. **模拟运行**：生成的可执行文件将在 “模拟运行时” 执行实际的模拟。

5. **波形跟踪和覆盖率分析**：如果启用了相关功能，可执行文件还可以生成设计的波形跟踪文件以供查看，并创建覆盖率分析数据用于后续分析。


### 安装
本节将讨论如何安装 Verilator。

#### 包管理器快速安装
使用发行版的包管理器是最简单的入门方式。（请注意，包管理器中的版本可能不是最新的，因此 Git 快速安装可能是更好的选择。）要通过包管理器安装：

```bash
apt-get install verilator   # 在Ubuntu24.04上或者WSL2 Ubuntu24.04
```
对于其他发行版，请参考 [Repology Verilator Distro Packages](https://repology.org/project/verilator/packages)。

#### pre-commit 快速安装
你可以使用 Verilator 的 pre-commit 钩子在提交代码前进行代码检查。它封装了 Verilator 构建的 Docker 容器，因此你需要在系统上安装 Docker 才能使用它。verilator 镜像会自动下载。

要使用该钩子，请在你的 `.pre-commit-config.yaml` 文件中添加以下内容：

```yaml
repos:
  - repo: https://github.com/verilator/verilator
    rev: v5.026  # 或更高版本
    hooks:
      - id: verilator
```

#### Git 快速安装
从 Git 安装 Verilator 提供了最大的灵活性；有关更多选项和详细信息，请参阅下面的详细构建说明。

简而言之，从 Git 安装的步骤如下：

```bash
# 先决条件：
#sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
#sudo apt-get install libgoogle-perftools-dev numactl perl-doc
#sudo apt-get install libfl2  # 仅限 Ubuntu（如果报错可以忽略）
#sudo apt-get install libfl-dev  # 仅限 Ubuntu（如果报错可以忽略）
#sudo apt-get install zlibc zlib1g zlib1g-dev  # 仅限 Ubuntu（如果报错可以忽略）

git clone https://github.com/verilator/verilator   # 仅首次需要

# 每次需要构建时：
unsetenv VERILATOR_ROOT  # 对于 csh；如果是 bash 可以忽略错误
unset VERILATOR_ROOT  # 对于 bash
cd verilator
git pull         # 确保 git 仓库是最新的
git tag          # 查看有哪些版本
#git checkout master      # 使用开发分支（例如最近的 bug 修复）
#git checkout stable      # 使用最新的稳定版本
#git checkout v{version}  # 切换到指定的发布版本

autoconf         # 创建 ./configure 脚本
./configure      # 配置并创建 Makefile
make -j `nproc`  # 构建 Verilator 本身（如果报错，可以尝试只使用 'make'）
sudo make install
```

### 示例1：创建二进制文件并执行
我们将把这个 SystemVerilog 示例编译成一个 Verilated 仿真二进制文件。有关更详细的示例，请参阅 **示例 C++ 执行**。

首先，你需要安装 Verilator，请参考 [安装说明](#installation)。简而言之，如果你是通过操作系统的包管理器安装的 Verilator，或者通过 `make install` 将 Verilator 安装到默认路径中，那么你不需要在环境中进行任何特殊设置，也不应该设置 `VERILATOR_ROOT`。但是，如果你是从源代码安装的 Verilator，并且希望从编译 Verilator 的目录中运行它，那么你需要指向该工具包：

```bash
# 如果使用的是操作系统分发的 Verilator，请不要执行以下操作
export VERILATOR_ROOT=/path/to/where/verilator/was/installed
export PATH=$VERILATOR_ROOT/bin:$PATH
```

接下来，我们创建一个示例 Verilog 文件：

```bash
mkdir test_our
cd test_our

cat >our.v <<'EOF'
  module our;
     initial begin $display("Hello World"); $finish; end
  endmodule
EOF
```

现在，我们对这个小示例运行 Verilator：

```bash
verilator --binary -j 0 -Wall our.v
```

分解这个命令：

- `--binary`：告诉 Verilator 执行创建仿真可执行文件所需的所有步骤。
- `-j 0`：使用机器上尽可能多的 CPU 线程进行 Verilate。
- `-Wall`：启用更强的 lint 警告。
- 最后，`our.v` 是我们的 SystemVerilog 设计文件。

现在，我们运行生成的二进制文件：

```bash
obj_dir/Vour
```

输出结果为：

```
Hello World
- our.v:2: Verilog $finish
```

为了更好地管理流程，建议使用 Makefile 来自动运行这些步骤，这样当源代码发生变化时，它会自动运行所有适当的步骤。为了帮助实现这一点，Verilator 可以生成一个 Makefile 依赖文件。

### 示例2：C++ 执行
我们将把这个示例编译成 C++ 代码。有关此 C++ 代码的详细说明和注释版本，请参阅 Verilator 分发版中的 `examples/make_tracing_c/sim_main.cpp` 文件。

首先，你需要安装 Verilator，请参考 [安装说明](#installation)。简而言之，如果你是通过操作系统的包管理器安装的 Verilator，或者通过 `make install` 将 Verilator 安装到默认路径中，那么你不需要在环境中进行任何特殊设置，也不应该设置 `VERILATOR_ROOT`。但是，如果你是从源代码安装的 Verilator，并且希望从编译 Verilator 的目录中运行它，那么你需要指向该工具包：

```bash
# 如果使用的是操作系统分发的 Verilator，请不要执行以下操作
export VERILATOR_ROOT=/path/to/where/verilator/was/installed
export PATH=$VERILATOR_ROOT/bin:$PATH
```

接下来，我们创建一个示例 Verilog 文件和一个 C++ 包装文件：

```bash
mkdir test_our
cd test_our

cat >our.v <<'EOF'
  module our;
     initial begin $display("Hello World"); $finish; end
  endmodule
EOF

cat >sim_main.cpp <<'EOF'
  #include "Vour.h"
  #include "verilated.h"
  int main(int argc, char** argv) {
      VerilatedContext* contextp = new VerilatedContext;
      contextp->commandArgs(argc, argv);
      Vour* top = new Vour{contextp};
      while (!contextp->gotFinish()) { top->eval(); }
      delete top;
      delete contextp;
      return 0;
  }
EOF
```

现在，我们对这个小示例运行 Verilator：

```bash
verilator --cc --exe --build -j 0 -Wall sim_main.cpp our.v
```

分解这个命令：

- `--cc`：生成 C++ 输出（而不是 SystemC 或仅进行 lint 检查）。
- `--exe`：与我们的 `sim_main.cpp` 包装文件一起使用，以便构建生成可执行文件，而不仅仅是库。
- `--build`：让 Verilator 自动调用 `make`。这样我们就不需要手动调用 `make` 作为单独的步骤。（你也可以编写自己的编译规则，并手动运行 `make`，如 **示例 SystemC 执行** 中所示。）
- `-j 0`：使用机器上尽可能多的 CPU 线程进行 Verilate。
- `-Wall`：启用更强的 lint 警告。
- 最后，`our.v` 是我们的 SystemVerilog 设计文件。

Verilator 完成后，我们可以在 `obj_dir` 目录下查看生成的 C++ 代码：

```bash
ls -l obj_dir
```
（有关生成文件的描述，请参阅 [Files Read/Written](#files-read-written)。）

现在，我们运行生成的可执行文件：

```bash
obj_dir/Vour
```

输出结果为：

```
Hello World
- our.v:2: Verilog $finish
```

为了更好地管理流程，建议使用 Makefile 来自动运行这些步骤，这样当源代码发生变化时，它会自动运行所有适当的步骤。为了帮助实现这一点，Verilator 可以生成一个 Makefile 依赖文件。

### 示例3：SystemC 执行
这是一个类似于 **示例 C++ 执行** 的示例，但使用 SystemC。我们还将显式运行 `make`。

首先，你需要安装 Verilator，请参考 [安装说明](#installation)。简而言之，如果你是通过操作系统的包管理器安装的 Verilator，或者通过 `make install` 将 Verilator 安装到默认路径中，那么你不需要在环境中进行任何特殊设置，也不应该设置 `VERILATOR_ROOT`。但是，如果你是从源代码安装的 Verilator，并且希望从编译 Verilator 的目录中运行它，那么你需要指向该工具包：

```bash
# 如果使用的是操作系统分发的 Verilator，请不要执行以下操作
export VERILATOR_ROOT=/path/to/where/verilator/was/installed
export PATH=$VERILATOR_ROOT/bin:$PATH
```

接下来，我们创建一个示例 Verilog 文件和一个 SystemC 包装文件：

```bash
mkdir test_our_sc
cd test_our_sc

cat >our.v <<'EOF'
  module our (clk);
     input clk;  // 需要时钟以获取初始激活
     always @(posedge clk)
        begin $display("Hello World"); $finish; end
  endmodule
EOF

cat >sc_main.cpp <<'EOF'
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
EOF
```

现在，我们对这个小示例运行 Verilator：

```bash
verilator --sc --exe -Wall sc_main.cpp our.v
```

在这个示例中，我们没有使用 `--build`，因此需要显式编译它：

```bash
make -j -C obj_dir -f Vour.mk Vour
```

现在，我们运行生成的可执行文件：

```bash
obj_dir/Vour
```

在 SystemC 横幅之后，我们会得到与 C++ 示例相同的输出：

```
SystemC 2.3.3-Accellera

Hello World
- our.v:4: Verilog $finish
```

为了更好地管理流程，建议使用 Makefile 来自动运行这些步骤，这样当源代码发生变化时，它会自动运行所有适当的步骤。有关示例，请参阅 Verilator 分发版中的 `examples` 目录。

### 示例4：生成波形文件

在C++代码中设置跟踪，创建波形文件
创建top.v并编写如下代码：
```verilog
module top (
    input a,
    input b,
    output f
);
    assign f = a ^ b;
endmodule
```

创建main.cpp并编写如下代码:
```c++
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
```

创建Makefile文件：
```Makefile
# Verilog仿真自动化脚本

.PHONY: all compile simulate view clean

all: compile simulate

compile:
	verilator --cc --exe --build -Wall --trace top.v main.cpp

simulate:
	./obj_dir/Vtop

view:
	gtkwave wave.vcd &

clean:
	rm -rf $(SIM_NAME) *.vcd obj_dir
```

使用如下命令：
```bash
make
```
即可发现vcd文件wave.vcd
然后使用命令就可以查看波形文件：
```bash
make view
```

### 示例5：在verilog代码中设置跟踪

在verilog代码中设置跟踪，创建波形文件，上面的Verilog代码增加testbech文件tb.v:
```verilog tb.v
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
```
修改C++代码main.cpp:
```C++ maiin.cpp
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
```
修改Makefile：
```Makefile
# Verilog仿真自动化脚本

.PHONY: all compile simulate view clean

all: compile simulate

compile:
	verilator --cc --exe --build -Wall --trace tb.v top.v main.cpp

simulate:
	./obj_dir/Vtb

view:
	gtkwave wave.vcd &

clean:
	rm -rf $(SIM_NAME) *.vcd obj_dir
```
然后输入命令：
```bash
make
```
可以得到以下结果：
```bash
verilator --cc --exe --build -Wall --trace tb.v top.v main.cpp
make[1]: Entering directory '/mnt/e/Github/FPGA-course/verilog/chapter2/test_xor2/obj_dir'
make[1]: Nothing to be done for 'default'.
make[1]: Leaving directory '/mnt/e/Github/FPGA-course/verilog/chapter2/test_xor2/obj_dir'
./obj_dir/Vtb
[0] Model running...

a = 1, b = 0, f = 1
a = 1, b = 1, f = 0
a = 1, b = 1, f = 0
a = 0, b = 0, f = 0
a = 1, b = 1, f = 0
a = 0, b = 1, f = 1
a = 0, b = 1, f = 1
a = 1, b = 0, f = 1
a = 0, b = 0, f = 0
a = 0, b = 0, f = 0
a = 1, b = 0, f = 1
a = 1, b = 1, f = 0
a = 0, b = 0, f = 0
a = 0, b = 1, f = 1
a = 1, b = 1, f = 0
a = 1, b = 0, f = 1
a = 0, b = 0, f = 0
a = 1, b = 1, f = 0
a = 1, b = 0, f = 1
```
