# sobel_03_uart_hdmi 实验说明

本实验实现 PC 端通过串口发送图像，ZYNQ PS 端接收图像并写入 AXI BRAM，PL 端从 BRAM 读取图像并通过 HDMI 输出到显示器。

当前版本用于验证 **UART -> PS -> AXI BRAM -> PL HDMI** 的完整显示链路。图像分辨率固定为 `128 x 72`，像素格式为 `RGB888`，HDMI 端将图像放大 10 倍显示到 `1280 x 720` 画面中。

## 1. 实验数据流

```text
PC 摄像头 / 图片
    -> USB 串口，115200 baud
    -> ZYNQ PS UART
    -> PS 软件解析帧数据
    -> AXI GP0
    -> AXI BRAM Controller
    -> Block RAM
    -> PL HDMI 读 BRAM
    -> RGB2DVI
    -> HDMI 显示器
```

当前实验保持串口波特率为 `115200`。这个波特率比较稳，但带宽较低，所以画面刷新速度会比较慢。

## 2. 工程文件

主要文件如下：

```text
sobel_03_uart_hdmi.xpr
    Vivado 工程

create_ps_uart_bram_hdmi_bd.tcl
    Block Design 生成脚本

sobel_03_uart_hdmi.srcs/sources_1/new/top.v
    顶层模块

sobel_03_uart_hdmi.srcs/sources_1/new/hdmi_pl_top.v
    PL 侧 HDMI 显示顶层

sobel_03_uart_hdmi.srcs/sources_1/new/hdmi_bram_display.v
    从 BRAM 读取 128x72 图像并放大显示

sobel_03_uart_hdmi.srcs/constrs_1/new/hdmi_out_test.xdc
    HDMI 管脚约束

ps_uart_bram_app/src/main.c
    PS 端 SDK 应用源码

sobel_03_uart_hdmi.sdk/ps_uart_bram_app/src/main.c
    SDK 工作区中的 PS 端应用源码

../host_camera_uart/camera_uart_sender.py
    PC 端摄像头 / 图片串口发送脚本

../host_camera_uart/README.md
    PC 端环境安装和运行说明

../host_camera_uart/requirements.txt
    PC 端 Python 依赖
```

上一级目录中的 `../hdmi_common` 是 Sobel 系列工程共用的 HDMI 基础依赖目录，不能删除。Vivado 工程文件中保留了指向该目录的相对路径，用于记录 `video_clock`、`rgb2dvi_0`、`hdmi_out_test.xdc` 和 HDMI IP repository 的来源。删除该目录后，重新打开工程或重新生成 IP 时可能出现 HDMI 相关文件缺失。

## 3. 硬件设计

### 3.1 打开 Vivado 工程

打开工程：

```text
D:\Github\FPGA-course\zynq7020-iage-processing\sobel_03_uart_hdmi\sobel_03_uart_hdmi.xpr
```

如果需要重新生成 Block Design，可以在 Vivado Tcl Console 中执行：

```tcl
cd D:/Github/FPGA-course/zynq7020-iage-processing/sobel_03_uart_hdmi
source create_ps_uart_bram_hdmi_bd.tcl
```

Block Design 中包含：

```text
ZYNQ7 Processing System
SmartConnect
AXI BRAM Controller
Block Memory Generator
BRAM_PORTB 外接到 PL HDMI 逻辑
```

BRAM 地址映射：

```text
BRAM base address = 0x40000000
BRAM range        = 64 KB
```

PS 写入 BRAM 的 framebuffer 格式：

```text
address = 0x40000000 + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

每个像素占 32 bit，低 24 bit 为 RGB888。

### 3.2 HDMI 显示逻辑

PL 端显示逻辑主要由以下模块完成：

```text
top.v
    连接 Block Design 和 HDMI PL 顶层

hdmi_pl_top.v
    生成视频时钟，连接 HDMI 读 BRAM 模块和 RGB2DVI

hdmi_bram_display.v
    产生 1280x720 时序，从 BRAM 读取 128x72 图像并做 10 倍放大
```

显示关系：

```text
BRAM 图像: 128 x 72
HDMI 输出: 1280 x 720
缩放倍数: 10 x 10
```

`hdmi_bram_display.v` 中已经处理 BRAM 读延迟，HDMI 同步信号和像素数据对齐后再输出。

### 3.3 生成 bitstream

在 Vivado 中依次执行：

```text
Run Synthesis
Run Implementation
Generate Bitstream
```

生成 bitstream 后，检查没有关键 DRC 错误。当前代码已经把 BRAM 读端复位改成同步复位，用于避免 RAMB36 异步控制相关 DRC。

## 4. SDK 软件工程

SDK 工作区目录：

```text
D:\Github\FPGA-course\zynq7020-iage-processing\sobel_03_uart_hdmi\sobel_03_uart_hdmi.sdk
```

Project Explorer 中通常有 3 个工程：

```text
top_hw_platform_0
    硬件平台

ps_uart_bram_app_bsp
    BSP 工程

ps_uart_bram_app
    PS 端应用工程
```

需要修改和运行的是：

```text
ps_uart_bram_app
```

### 4.1 当前 SDK 关键配置

PS 端 `main.c` 当前配置：

```c
#define IMG_WIDTH        128U
#define IMG_HEIGHT       72U
#define RGB888_FORMAT    0x18U
#define UART_BAUD_RATE   115200U
#define UART_WAIT_MS     2000U
```

串口波特率已经改为 `115200`。

### 4.2 编译 SDK 工程

在 SDK 中执行：

```text
右键 ps_uart_bram_app_bsp -> Re-generate BSP Sources
右键 ps_uart_bram_app     -> Clean Project
右键 ps_uart_bram_app     -> Build Project
```

如果只改了 `main.c`，通常重新 Build `ps_uart_bram_app` 即可。

### 4.3 下载 FPGA 和运行 PS 程序

先下载 bitstream：

```text
Xilinx -> Program FPGA
```

bitstream 通常在：

```text
sobel_03_uart_hdmi.runs/impl_1/top.bit
```

然后运行 PS 程序：

```text
右键 ps_uart_bram_app -> Run As -> Launch on Hardware (System Debugger)
```

如果 SDK 进入 Debug 界面，可以通过下面方式回到原来的 C/C++ 工程界面：

```text
右上角点击 C/C++ 图标
```

或者：

```text
Window -> Perspective -> Open Perspective -> C/C++
```

## 5. 串口配置

串口调试助手配置：

```text
端口号:  根据开发板实际端口选择，例如 COM7
波特率:  115200
数据位:  8
校验位:  None
停止位:  1
流控:    None
```

PS 程序启动后，串口调试助手应该看到：

```text
PS UART BRAM HDMI display
BRAM base: 0x40000000, baud: 115200
waiting for frame header
```

`waiting for frame header` 表示 PS 程序正在等待 PC 端发送图像帧，这是正常现象。

注意：同一个 COM 口同一时间只能被一个程序打开。运行 Python 发送脚本前，需要关闭串口调试助手。

## 6. PC 端 Python 环境

PC 端脚本位于：

```text
D:\Github\FPGA-course\zynq7020-iage-processing\host_camera_uart
```

推荐使用 Anaconda 创建独立环境。

### 6.1 安装 Anaconda

1. 进入 Anaconda 官网下载 Windows 版本安装包。
2. 按默认选项安装。
3. 安装完成后，打开 Anaconda Prompt。
4. 检查 conda 是否可用：

```bash
conda --version
```

### 6.2 创建 fpga 虚拟环境

本实验指定 Python 版本为 `3.13`：

```bash
conda create -n fpga python=3.13 -y
conda activate fpga
```

进入 PC 端脚本目录：

```bash
cd D:\Github\FPGA-course\zynq7020-iage-processing\host_camera_uart
```

安装依赖：

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

检查依赖是否安装成功：

```bash
python -c "import cv2, numpy, serial; print('ok')"
```

如果输出 `ok`，说明环境可以使用。

## 7. PC 端发送图像

### 7.1 摄像头发送

关闭串口调试助手后，在 Anaconda Prompt 中运行：

```bash
conda activate fpga
cd D:\Github\FPGA-course\zynq7020-iage-processing\host_camera_uart
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --preview
```

其中：

```text
--port COM7
    改成自己开发板对应的串口号

--baud 115200
    必须和 SDK 程序一致

--camera 0
    使用默认摄像头

--fps 0.2
    每 5 秒左右发送 1 帧，适合 115200 baud

--preview
    在 PC 上显示预览窗口
```

### 7.2 图片发送

也可以发送单张图片：

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --image test.jpg --once --preview
```

### 7.3 串口较慢时的稳定发送

如果出现丢行、超时或画面不完整，可以增加行间延时：

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --line-delay 0.001 --preview
```

## 8. 串口协议

PC 端每帧发送一个 frame header，然后按行发送图像数据。

### 8.1 帧头

```text
0x55 0xAA width_l width_h height_l height_h format
```

当前固定为：

```text
width  = 128
height = 72
format = 0x18
```

`0x18` 表示 RGB888。

### 8.2 行头

每一行发送前都有 line header：

```text
0x33 0xCC row_l row_h
```

`row` 从 `0` 到 `71`。

### 8.3 像素数据

每行像素数据为：

```text
128 个 RGB888 像素
每个像素 3 字节: R G B
```

PS 接收后写入 BRAM：

```text
0x00RRGGBB
```

## 9. 完整测试流程

### 9.1 只测试 FPGA 和 PS 程序

1. 打开 Vivado 工程。
2. Generate Bitstream。
3. 打开 SDK。
4. Build `ps_uart_bram_app`。
5. `Xilinx -> Program FPGA` 下载 bitstream。
6. `Run As -> Launch on Hardware (System Debugger)` 运行 PS 程序。
7. 打开串口调试助手，配置 `115200 8N1`。
8. 确认串口打印：

```text
PS UART BRAM HDMI display
BRAM base: 0x40000000, baud: 115200
waiting for frame header
```

此时显示器应有 HDMI 输出。

### 9.2 测试 PC 到 HDMI 的完整链路

1. 关闭串口调试助手。
2. 打开 Anaconda Prompt。
3. 进入 `fpga` 环境。
4. 运行 PC 端发送脚本：

```bash
conda activate fpga
cd D:\Github\FPGA-course\zynq7020-iage-processing\host_camera_uart
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --preview
```

5. 观察 HDMI 显示器。
6. 显示器应能看到 PC 摄像头图像，只是刷新比较慢。

## 10. 当前实验现象

当前实测现象：

```text
串口能输出启动信息
串口能输出 waiting for frame header
显示器能正常输出画面
PC 发送脚本运行后，HDMI 画面能更新
```

这是当前保持的工作状态。

## 11. 帧率说明

当前串口波特率为 `115200`，实际 UART 8N1 传输时每个字节约需要 10 bit。

理论有效字节率约为：

```text
115200 / 10 = 11520 byte/s
```

一帧 `128 x 72` 的 RGB888 图像数据大约为：

```text
128 * 72 * 3 = 27648 byte
```

再加上帧头和行头，一帧约 `27 KB`。因此在 `115200` 波特率下，理论最高帧率不到 `0.5 fps`，实际运行时建议使用：

```text
--fps 0.2
```

如果想明显提高帧率，需要后续提高串口波特率、降低图像分辨率、减少颜色字节数，或者换成 USB / Ethernet / DMA 等更高带宽的数据通道。当前实验为了稳定，保持 `115200`。

## 12. 常见问题

### 12.1 串口没有任何输出

检查：

```text
是否已经 Program FPGA
是否已经 Run PS 程序，而不是只下载 bitstream
串口号是否正确
串口是否为 115200 8N1
是否 Build 了最新的 ps_uart_bram_app
串口是否被其他软件占用
```

### 12.2 串口有输出，但是 HDMI 没有输出

检查：

```text
显示器是否切到正确 HDMI 输入
bitstream 是否是最新生成的 top.bit
Vivado 顶层是否为 top.v
hdmi_out_test.xdc 管脚约束是否启用
HDMI 线和开发板 HDMI 接口是否正常
```

### 12.3 HDMI 有输出，但是 PC 发送后画面不更新

检查：

```text
运行 Python 脚本前是否关闭了串口调试助手
Python 脚本的 --port 是否正确
Python 脚本的 --baud 是否为 115200
Python 脚本的 --fps 是否不要太高
SDK 程序是否仍在运行
```

### 12.4 串口打印 frame error

常见错误含义：

```text
frame error -1
    图像宽度、高度或格式不匹配

frame error -2
    行号不匹配，通常是串口数据丢失或发送太快

frame error -5
    等待行头超时

frame error -6
    等待行号超时

frame error -7
    等待像素数据超时
```

处理方法：

```text
降低 --fps
增加 --line-delay
检查 USB 串口连接
确认 PC 端和 SDK 端波特率一致
```

### 12.5 一直打印 waiting for frame header

这说明 PS 程序运行正常，但还没有收到 PC 端发送的图像帧。

处理方法：

```text
关闭串口调试助手
运行 camera_uart_sender.py
确认 COM 口正确
确认 baud 为 115200
```

## 13. 后续可扩展方向

当前实验已经验证串口输入图像并 HDMI 显示。后续可以在这个基础上继续扩展：

```text
在 PL 端加入 Sobel 卷积模块
把 RGB 图像转灰度后做边缘检测
提高输入通道带宽
改成 DMA framebuffer
增加双缓冲，减少画面撕裂
提高图像分辨率和帧率
```

## 14. 课程设计安排与可选扩展方案

本课程设计建议采用“基础实验复现 + 可选扩展”的组织方式。所有学生必须先完成教师提供工程的复现，确保仿真、上板、HDMI 显示、SDK 下载和 UART 图像传输流程全部打通；在此基础上，每组选择一个扩展方向完成设计、验证和报告撰写。

### 14.1 时间安排

当前课程设计周期较短，上机时间有限，建议按以下节奏推进：

| 时间 | 任务 | 学生提交物 |
| --- | --- | --- |
| 第 15 周周四上午 | 提交仿真报告；检查 Vivado、SDK、Python 环境是否可用 | 仿真报告、关键波形截图 |
| 第 15 周周四下午 | 完成基础上板实验，复现教师提供工程结果 | HDMI 显示照片或视频、串口截图、问题记录 |
| 第 15 周周五至第 16 周周一 | 整理初步实验报告，补充系统框图、关键代码说明和实验现象 | 初步实验报告草稿 |
| 第 16 周周二上午 | 提交初步实验报告，确认基础实验复现结果 | 初步实验报告 |
| 第 16 周周二下午 | 开始扩展实验开发，完成扩展方案的初步联调 | 扩展功能初版、调试记录 |
| 第 16 周周四上午 | 完成扩展实验主要功能，补充资源利用率和时序分析 | 扩展实验截图、资源报告 |
| 第 16 周周五上午 | 完成最终联调和演示验收 | 可运行工程、演示视频 |
| 第 16 周周五下午 | 完成最终课程设计报告 | 最终报告、工程归档 |

### 14.2 必做基础任务

所有学生必须完成以下基础任务：

1. 完成 Sobel 或图像显示相关 RTL 仿真，能够说明输入、输出和关键时序。
2. 完成 HDMI 测试图案或图像显示实验，确认显示链路正常。
3. 完成 PS 端 SDK 程序下载和运行，能够通过串口观察程序启动信息。
4. 完成 PC 端 Python 脚本到 ZYNQ 的 UART 图像发送实验。
5. 能够说明 `UART -> PS -> AXI BRAM -> PL HDMI` 的数据流。
6. 记录 Vivado 资源利用率和时序结果。

建议教师提供以下基础工程或代码，方便学生在此基础上扩展：

```text
sobel_00_rtl_sim
    Sobel 核心或图像处理模块的仿真工程

sobel_01_hdmi_pattern
    HDMI 测试图案显示基础工程

sobel_02_hdmi_sobel
    HDMI + Sobel 处理基础工程

sobel_03_uart_hdmi
    PC 串口传图、PS 写 BRAM、PL HDMI 显示基础工程

sobel_04_uart_sobel_hdmi
    UART 输入图像、PL Sobel 处理、HDMI 显示综合参考工程

host_camera_uart/camera_uart_sender.py
    PC 端摄像头或图片发送脚本
```

### 14.3 可选扩展方案 A：Sobel 阈值可调与显示模式切换

难度：基础扩展，适合大多数学生。

实验目标：

1. 通过 UART 命令设置 Sobel 边缘检测阈值。
2. 支持多种显示模式切换，例如原图、灰度图、边缘图、边缘叠加图。
3. 对比不同阈值下的边缘检测效果。

建议命令格式：

```text
m0
    显示原图或输入图像

m1
    显示灰度图

m2
    显示 Sobel 边缘图

m3
    显示原图叠加边缘结果

t80
    设置边缘阈值为 80
```

教师建议提供的基础代码：

```text
UART 命令解析模板
    解析 mode 和 threshold 命令

threshold_reg 阈值寄存器模板
    保存 PS 或 UART 配置的阈值

display_mode_select.v
    根据模式选择不同图像输出

sobel_core.v
    已验证的 Sobel 卷积核心
```

验收要求：

1. 至少支持 3 种显示模式。
2. 至少演示 3 个不同阈值的处理效果。
3. 报告中给出阈值变化对边缘结果的影响分析。

### 14.4 可选扩展方案 B：多种边缘检测算子对比

难度：标准扩展，适合有一定 Verilog 基础的学生。

实验目标：

1. 在 Sobel 基础上增加 Prewitt 或 Roberts 边缘检测算子。
2. 支持通过 UART、按键或拨码开关切换算子。
3. 对比不同算子的图像效果、资源占用和时序结果。

教师建议提供的基础代码：

```text
sobel_core.v
    Sobel 算子参考实现

prewitt_core_template.v
    Prewitt 算子半成品模板

edge_operator_select.v
    算子输出选择模块

edge_operator_tb.v
    多算子仿真测试模板
```

验收要求：

1. 至少完成 Sobel 和另一种边缘检测算子。
2. 能够在板卡上切换不同算子显示结果。
3. 报告中比较不同算子的计算复杂度、显示效果和资源利用率。

### 14.5 可选扩展方案 C：图像预处理与 Sobel 组合实验

难度：标准扩展，适合对图像处理流程感兴趣的学生。

实验目标：

1. 在 Sobel 前加入简单图像预处理模块。
2. 可选实现灰度增强、3x3 均值滤波或简化中值滤波。
3. 比较“直接 Sobel”和“预处理后 Sobel”的边缘检测效果。

教师建议提供的基础代码：

```text
line_buffer_3x3.v
    3x3 窗口生成模块

mean_filter_3x3_template.v
    3x3 均值滤波模板

rgb_to_gray.v
    RGB 转灰度模块

sobel_core.v
    Sobel 卷积核心

image_filter_tb.v
    图像预处理仿真模板
```

验收要求：

1. 至少完成一种预处理方法。
2. 能够切换直接 Sobel 和预处理后 Sobel。
3. 报告中说明预处理对噪声、边缘连续性和资源消耗的影响。

### 14.6 可选扩展方案 D：PC 到 ZYNQ 的高速图像传输实验

难度：挑战扩展，建议能力较强的小组选择。

本方向不建议直接接入真实网络摄像头的 RTSP/H.264 视频流。真实网络摄像头通常涉及 RTSP、RTP、H.264/H.265 解码、帧缓存管理等内容，工作量和风险都较高。更适合课程设计的做法是由 PC 端模拟图像源，通过串口高速模式或 UDP 将图像帧发送到 ZYNQ。

实验目标：

1. PC 端使用 Python/OpenCV 读取摄像头或图片。
2. 将图像转换为较低分辨率灰度图或 RGB 图。
3. 通过更高带宽的数据通道发送到 ZYNQ。
4. ZYNQ 接收后写入缓存，并通过 PL HDMI 显示或 Sobel 处理。

建议分级实现：

```text
基础版
    串口发送 128x72 RGB888 或灰度图，优化协议和发送稳定性

提高版
    使用更高波特率或更紧凑的灰度格式，提高帧率

挑战版
    使用 UDP 发送 320x240 灰度图，PS 端基于 lwIP 接收
```

教师建议提供的基础代码：

```text
pc_image_sender.py
    PC 端图片或摄像头发送脚本

udp_frame_sender.py
    PC 端 UDP 分包发送模板

zynq_uart_frame_receiver.c
    ZYNQ PS 端 UART 接收模板

zynq_udp_frame_receiver.c
    ZYNQ PS 端 UDP 接收模板

frame_protocol.md
    帧头、行头、分包编号、校验方式说明
```

验收要求：

1. 能够说明图像帧格式和传输协议。
2. 能够完成至少一种传输方式的稳定显示。
3. 报告中给出理论带宽、实际帧率和瓶颈分析。

### 14.7 扩展题目选择建议

建议教师发布时采用分层要求：

```text
A 题：基础扩展
    适合大多数学生，重点考察 UART 控制、寄存器配置和显示模式切换。

B 题 / C 题：标准扩展
    适合有一定硬件设计基础的学生，重点考察图像处理流水线设计。

D 题：挑战扩展
    适合能力较强的小组，重点考察 PS 端通信、数据吞吐和系统联调能力。
```

最终评分时可综合考虑完成质量和技术难度。建议所有小组至少完成 A、B、C、D 中的一个扩展方向，不要求所有小组选择同一题目。

### 14.8 建议评分结构

| 项目 | 分值 |
| --- | ---: |
| 基础实验复现 | 30 |
| 仿真报告 | 15 |
| 初步实验报告 | 15 |
| 扩展功能完成度 | 20 |
| 最终报告质量 | 15 |
| 演示与答辩 | 5 |

最终报告建议包含以下内容：

1. 课程设计任务说明。
2. 系统总体结构和数据流。
3. 基础实验复现过程。
4. 所选扩展方案的设计原理。
5. 关键代码说明。
6. 仿真结果和上板结果。
7. 资源利用率、时序结果和性能分析。
8. 问题记录与总结。
