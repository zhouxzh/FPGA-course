# sobel_04_uart_sobel_hdmi 实验说明

本实验在 `sobel_03_uart_hdmi` 的基础上继续完成 Sobel 边缘检测显示。

数据仍然由 PC 端通过串口发送到 ZYNQ7020，PS 端负责接收 `128 x 72` RGB888 图像并写入 AXI BRAM，PL 端从 BRAM 读取原始图像，完成灰度转换和 Sobel 运算，最后把边缘检测结果通过 HDMI 显示到显示器上。

## 实验步骤总览

建议在已经完成 `sobel_03_uart_hdmi` 的基础上再做本实验：

1. 打开 `sobel_04_uart_sobel_hdmi.xpr`，确认顶层、Block Design、HDMI 约束和 Sobel 相关源码存在。
2. 检查 `hdmi_pl_top.v` 是否例化 `hdmi_bram_sobel_display`。
3. 在 Vivado 中运行 Synthesis、Implementation，并生成 `top.bit`。
4. 下载 bitstream 到开发板。
5. 打开 SDK 工作区，重新生成 BSP，编译并运行 `ps_uart_bram_app`。
6. 用串口调试助手确认启动信息为 `PS UART PL Sobel HDMI display`。
7. 关闭串口调试助手，使用 `host_camera_uart` 中的 GUI 或命令行脚本发送图片。
8. 观察 HDMI 是否显示输入图像的 Sobel 边缘结果。
9. 保存 HDMI 照片、串口输出截图、资源利用率和时序结果。

## 1. 实验目标

```mermaid
flowchart LR
    pc["PC 摄像头 / 图片"] --> uart["UART<br/>115200"]
    uart --> ps["ZYNQ PS UART"]
    ps --> write["PS 写入 AXI BRAM<br/>原始 RGB 图像"]
    write --> bram["AXI BRAM<br/>0x00RRGGBB"]
    bram --> read["PL 读取 BRAM 原图"]
    read --> gray["PL rgb_to_gray"]
    gray --> sobel["PL sobel_core"]
    sobel --> edge["PL edge_mem"]
    edge --> hdmi["HDMI 显示<br/>Sobel 边缘图"]

    classDef pc fill:#dcfce7,stroke:#16a34a,color:#0f172a,stroke-width:2px;
    classDef ps fill:#e0f2fe,stroke:#0284c7,color:#0f172a,stroke-width:2px;
    classDef mem fill:#ede9fe,stroke:#7c3aed,color:#0f172a,stroke-width:2px;
    classDef pl fill:#fef3c7,stroke:#d97706,color:#0f172a,stroke-width:2px;
    classDef out fill:#fae8ff,stroke:#c026d3,color:#0f172a,stroke-width:2px;
    class pc,uart pc;
    class ps,write ps;
    class bram,edge mem;
    class read,gray,sobel pl;
    class hdmi out;
```

和 `sobel_03_uart_hdmi` 的区别：

```mermaid
flowchart LR
    exp3["sobel_03<br/>HDMI 显示串口收到的原始 RGB 图像"] --> exp4["sobel_04<br/>HDMI 显示 PL Sobel 运算后的灰度边缘图"]

    classDef old fill:#e0f2fe,stroke:#0284c7,color:#0f172a,stroke-width:2px;
    classDef new fill:#fef3c7,stroke:#d97706,color:#0f172a,stroke-width:2px;
    class exp3 old;
    class exp4 new;
```

当前保持已经调通的稳定串口配置：

```text
baud   = 115200
format = 8N1
image  = 128 x 72 RGB888
fps    = 0.2
```

## 2. 主要文件

```mermaid
flowchart TB
    project["sobel_04_uart_sobel_hdmi.xpr<br/>Vivado 工程"]
    project --> bd["create_ps_uart_sobel_hdmi_bd.tcl<br/>PS UART + AXI BRAM BD 脚本"]
    project --> top["top.v<br/>连接 ZYNQ PS BD 和 HDMI PL 顶层"]
    top --> pltop["hdmi_pl_top.v<br/>video_clock + rgb2dvi + Sobel 显示模块"]
    pltop --> display["hdmi_bram_sobel_display.v<br/>BRAM 读图 + PL Sobel + HDMI 数据输出"]
    display --> gray["rgb_to_gray.v<br/>RGB888 转灰度"]
    display --> sobel["sobel_core.v<br/>Sobel 卷积核心"]
    project --> xdc["hdmi_out_test.xdc<br/>HDMI 管脚约束"]
    project --> sdkmain["sobel_04_uart_sobel_hdmi.sdk/ps_uart_bram_app/src/main.c<br/>SDK 中运行的 PS 程序"]
    project --> backup["ps_uart_sobel_bram_app/src/main.c<br/>PS 端源码备份"]
    host["../host_camera_uart/"] --> sender["camera_uart_sender.py<br/>PC 端串口发送脚本"]

    classDef project fill:#e0f2fe,stroke:#0284c7,color:#0f172a,stroke-width:2px;
    classDef script fill:#dcfce7,stroke:#16a34a,color:#0f172a,stroke-width:2px;
    classDef pl fill:#fef3c7,stroke:#d97706,color:#0f172a,stroke-width:2px;
    classDef ps fill:#ede9fe,stroke:#7c3aed,color:#0f172a,stroke-width:2px;
    classDef constr fill:#fee2e2,stroke:#dc2626,color:#0f172a,stroke-width:2px;
    classDef host fill:#ccfbf1,stroke:#0f766e,color:#0f172a,stroke-width:2px;
    class project project;
    class bd script;
    class top,pltop,display,gray,sobel pl;
    class sdkmain,backup ps;
    class xdc constr;
    class host,sender host;
```

## 3. 硬件结构

Block Design 仍然复用第 3 步的硬件链路：

```mermaid
flowchart LR
    ps["processing_system7_0<br/>M_AXI_GP0"] --> smart["SmartConnect"]
    smart --> ctrl["AXI BRAM Controller"]
    ctrl --> porta["Block Memory Generator<br/>Port A"]
    porta --> bram["Shared BRAM"]
    bram --> portb["Block Memory Generator<br/>Port B"]
    portb --> pl["PL Sobel HDMI display"]

    classDef ps fill:#e0f2fe,stroke:#0284c7,color:#0f172a,stroke-width:2px;
    classDef axi fill:#ede9fe,stroke:#7c3aed,color:#0f172a,stroke-width:2px;
    classDef pl fill:#fef3c7,stroke:#d97706,color:#0f172a,stroke-width:2px;
    class ps ps;
    class smart,ctrl,porta,bram,portb axi;
    class pl pl;
```

BRAM 地址：

```text
base  = 0x40000000
range = 64 KB
```

PS 写入 BRAM 的原始图像格式：

```text
address = 0x40000000 + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

PL 端 `hdmi_bram_sobel_display.v` 每个 HDMI 帧开始时扫描一遍 BRAM 中的 `128 x 72` 原图，然后完成：

```mermaid
flowchart LR
    bram["BRAM RGB888"] --> gray["rgb_to_gray"]
    gray --> sobel["sobel_core"]
    sobel --> edge["edge_mem"]

    classDef data fill:#e0f2fe,stroke:#0284c7,color:#0f172a,stroke-width:2px;
    classDef alg fill:#fef3c7,stroke:#d97706,color:#0f172a,stroke-width:2px;
    classDef mem fill:#ede9fe,stroke:#7c3aed,color:#0f172a,stroke-width:2px;
    class bram data;
    class gray,sobel alg;
    class edge mem;
```

HDMI 显示时从 `edge_mem` 读取 8 bit 灰度边缘值，并复制到 RGB 三个通道：

```text
R = edge
G = edge
B = edge
```

最终显示为黑白边缘图。

## 4. Vivado 使用流程

打开工程：

```text
D:\Github\FPGA-course\zynq7020-image-processing\sobel_04_uart_sobel_hdmi\sobel_04_uart_sobel_hdmi.xpr
```

如果需要重新生成 Block Design，在 Vivado Tcl Console 中执行：

```tcl
cd D:/Github/FPGA-course/zynq7020-image-processing/sobel_04_uart_sobel_hdmi
source create_ps_uart_sobel_hdmi_bd.tcl
```

然后依次执行：

```text
Run Synthesis
Run Implementation
Generate Bitstream
```

生成 bitstream 后，下载 FPGA：

```text
Xilinx -> Program FPGA
```

bitstream 通常位于：

```text
sobel_04_uart_sobel_hdmi.runs/impl_1/top.bit
```

如果工程还没有生成 `.runs` 目录，说明还没有在 Vivado 中重新综合和实现。

## 5. SDK 使用流程

SDK 工作区：

```text
D:\Github\FPGA-course\zynq7020-image-processing\sobel_04_uart_sobel_hdmi\sobel_04_uart_sobel_hdmi.sdk
```

由于本工程从 `sobel_03` 复制而来，SDK Project Explorer 中可能仍然显示：

```text
top_hw_platform_0
ps_uart_bram_app_bsp
ps_uart_bram_app
```

这里直接编译运行 `ps_uart_bram_app` 即可。它的 `main.c` 已经改成 `sobel_04` 版本，启动时会打印：

```text
PS UART PL Sobel HDMI display
BRAM base: 0x40000000, baud: 115200, image: 128x72
```

SDK 中执行：

```text
右键 ps_uart_bram_app_bsp -> Re-generate BSP Sources
右键 ps_uart_bram_app     -> Clean Project
右键 ps_uart_bram_app     -> Build Project
右键 ps_uart_bram_app     -> Run As -> Launch on Hardware (System Debugger)
```

PS 程序功能：

```text
1. 初始化 PS UART，波特率 115200
2. 先向 BRAM 写入一张 128x72 彩色测试图
3. 循环等待 PC 端发送 RGB888 图像
4. 接收后把原始 RGB 图像写入 BRAM
5. Sobel 运算由 PL 自动读取 BRAM 并完成
```

## 6. 串口配置

串口调试助手配置：

```text
端口号:  例如 COM7
波特率:  115200
数据位:  8
校验位:  None
停止位:  1
流控:    None
```

运行 PS 程序后，串口应看到：

```text
PS UART PL Sobel HDMI display
BRAM base: 0x40000000, baud: 115200, image: 128x72
waiting for frame header
```

`waiting for frame header` 表示板子正在等待 PC 端发送图像帧，是正常现象。

## 7. PC 端发送视频

PC 端继续使用：

```text
D:\Github\FPGA-course\zynq7020-image-processing\host_camera_uart
```

先进入 Anaconda 环境：

```bash
conda activate fpga
cd D:\Github\FPGA-course\zynq7020-image-processing\host_camera_uart
```

发送摄像头视频：

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --preview
```

发送单张图片：

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --image test.jpg --once --preview
```

如果出现串口错误或画面不稳定，可以增加行间延时：

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --line-delay 0.001 --preview
```

注意：运行 Python 脚本前必须关闭串口调试助手，因为同一个 COM 口不能被两个程序同时打开。

## 8. 预期现象

只下载 bitstream 并运行 PS 程序后：

```text
串口显示 sobel_04 启动信息
HDMI 显示测试图经过 PL Sobel 后的边缘图
```

运行 PC 摄像头发送脚本后：

```text
串口打印 received frame 1、received frame 2 ...
HDMI 显示摄像头画面的 Sobel 边缘检测结果
```

画面是黑白边缘图，不再是彩色原图。

## 9. 帧率说明

当前 `115200` baud 下，一帧 `128 x 72 RGB888` 数据大约为：

```text
128 * 72 * 3 = 27648 byte
```

UART 8N1 的有效吞吐约为：

```text
115200 / 10 = 11520 byte/s
```

所以输入视频帧率仍然很低，推荐：

```text
--fps 0.2
```

PL 端 Sobel 运算本身很快，瓶颈主要是串口输入带宽。

## 10. 常见问题

### 10.1 串口没有 sobel_04 启动信息

检查：

```text
是否运行了 sobel_04 SDK 工作区里的 ps_uart_bram_app
是否重新 Build 了最新 main.c
是否下载了 sobel_04 的 bitstream
串口是否为 115200 8N1
COM 口是否正确
```

如果串口仍显示：

```text
PS UART BRAM HDMI display
```

说明你运行的还是 `sobel_03` 的旧 ELF。

### 10.2 HDMI 显示原图而不是边缘图

检查：

```text
Vivado 是否打开 sobel_04_uart_sobel_hdmi.xpr
hdmi_pl_top.v 中是否例化 hdmi_bram_sobel_display
工程 Sources 中是否包含 rgb_to_gray.v、sobel_core.v、hdmi_bram_sobel_display.v
是否重新 Generate Bitstream 并 Program FPGA
```

### 10.3 HDMI 黑屏

检查：

```text
显示器是否能识别 1280x720 HDMI 输入
video_clock 和 rgb2dvi_0 是否仍然存在
hdmi_out_test.xdc 是否启用
是否有 Vivado 综合/实现错误
```

如果串口正常、HDMI 黑屏，先回到 `sobel_03_uart_hdmi` 验证 HDMI 基线是否仍然正常。

### 10.4 画面边缘不明显

Sobel 输出取决于输入画面的亮度变化。如果画面过暗、过亮或背景太平，边缘会比较少。

可以测试：

```text
把摄像头对准有明显轮廓的物体
使用黑白反差明显的图片
打开 PC 端 --preview 确认输入图像正常
```

### 10.5 frame error

常见错误：

```text
frame error -1
    宽度、高度或格式不匹配

frame error -2
    行号不匹配，通常是串口数据丢失

frame error -5/-6/-7
    中途等待行头、行号或像素数据超时
```

处理方法：

```text
确认 --baud 115200
降低 --fps
增加 --line-delay 0.001
检查 USB 线和 COM 口
```

## 11. 第一周基础扩展

本实验的基础扩展围绕 PL Sobel 输出显示，控制在 1 个 Verilog 文件或 1 个参数对比实验内完成。学生至少完成 1 项，并把修改说明和 HDMI 现象写入初步实验报告。

| 选题 | 修改范围 | 验收标准 |
| --- | --- | --- |
| 固定阈值二值化边缘显示 | `hdmi_bram_sobel_display.v` 的 Sobel 输出到 RGB 映射 | HDMI 显示黑白二值边缘图，报告给出阈值 |
| 边缘反色显示 | `hdmi_bram_sobel_display.v` 的 RGB 输出映射 | 原黑底白边变成白底黑边，摄像头输入后仍能显示边缘 |
| 彩色边缘标记 | `hdmi_bram_sobel_display.v` 的 RGB 输出映射 | 边缘用红色、绿色或蓝色突出显示 |
| Sobel 阈值参数对比 | `hdmi_bram_sobel_display.v` 或 `sobel_core.v` 中的固定阈值常量 | 至少对比 3 个阈值下的 HDMI 效果，并记录资源利用率 |

## 12. 后续实验入口

`sobel_04` 是后续上位机控制实验的基础工程。完成本实验后，进入 `sobel_05_pc_control_display`，在本工程基础上继续完成：

1. 上位机控制 Sobel 二值化阈值。
2. 上位机控制边缘彩色叠加。
3. 上位机控制灰度图、边缘图和叠加图显示模式切换。

这些内容不再作为 `sobel_04` 的普通选做项，而是在 `sobel_05_pc_control_display` 中作为基础实验要求完成。
