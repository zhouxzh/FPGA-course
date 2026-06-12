# sobel_03_uart_hdmi 实验说明

本实验实现 PC 端通过串口发送图像，ZYNQ PS 端接收图像并写入 AXI BRAM，PL 端从 BRAM 读取图像并通过 HDMI 输出到显示器。

当前版本用于验证 **UART -> PS -> AXI BRAM -> PL HDMI** 的完整显示链路。图像分辨率固定为 `128 x 72`，像素格式为 `RGB888`，HDMI 端将图像放大 10 倍显示到 `1280 x 720` 画面中。

## 实验步骤总览

建议按下面顺序完成，不要跳过 HDMI 或 SDK 的单独验证：

1. 打开 `sobel_03_uart_hdmi.xpr`，确认顶层、Block Design、HDMI 约束和 `hdmi_bram_display.v` 存在。
2. 在 Vivado 中运行 Synthesis、Implementation，并生成 `top.bit`。
3. 下载 bitstream 到开发板，确认 HDMI 有基础输出。
4. 打开 SDK 工作区，重新生成 BSP，编译并运行 `ps_uart_bram_app`。
5. 用串口调试助手确认 PS 程序打印启动信息和 `waiting for frame header`。
6. 关闭串口调试助手，使用 `host_camera_uart` 中的 GUI 或命令行脚本发送图片。
7. 观察 HDMI 是否显示 PC 端发送的原始图像。
8. 保存 HDMI 照片、串口输出截图、资源利用率和时序结果。

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
D:\Github\FPGA-course\zynq7020-image-processing\sobel_03_uart_hdmi\sobel_03_uart_hdmi.xpr
```

如果需要重新生成 Block Design，可以在 Vivado Tcl Console 中执行：

```tcl
cd D:/Github/FPGA-course/zynq7020-image-processing/sobel_03_uart_hdmi
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
D:\Github\FPGA-course\zynq7020-image-processing\sobel_03_uart_hdmi\sobel_03_uart_hdmi.sdk
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
D:\Github\FPGA-course\zynq7020-image-processing\host_camera_uart
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
cd D:\Github\FPGA-course\zynq7020-image-processing\host_camera_uart
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
cd D:\Github\FPGA-course\zynq7020-image-processing\host_camera_uart
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
cd D:\Github\FPGA-course\zynq7020-image-processing\host_camera_uart
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

## 13. 可选扩展

本实验的扩展围绕串口输入后的 HDMI 原图显示，属于第一周基础扩展。学生至少完成 1 项；不要求修改 PC 端 GUI，也不要求加入 Sobel。

| 选题 | 修改范围 | 验收标准 |
| --- | --- | --- |
| 修改 HDMI 背景颜色 | `hdmi_bram_display.v` 的非图像区域 RGB 输出 | 串口图像仍正常显示，背景颜色按设计变化 |
| 调整图像显示位置 | `hdmi_bram_display.v` 的坐标映射 | 128x72 图像能显示在左上、居中或指定区域 |
| 增加图像边框 | `hdmi_bram_display.v` 的显示区域判断 | HDMI 图像周围出现单色边框，图像内容不被破坏 |
| 串口帧率与稳定性记录 | 不改硬件，调整 PC 端运行参数 | 对比 2 到 3 组 `--fps` 或 `--line-delay`，记录是否出现 `frame error` |

不建议在本实验中做 UDP、DMA、网络摄像头、双缓冲或 PC 端 GUI 修改。这些内容工作量较大，不适合作为第一周基础扩展。
