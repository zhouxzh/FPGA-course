# sobel_05_pc_control_display 实验说明

本实验在 `sobel_04_uart_sobel_hdmi` 的基础上，增加“上位机控制显示”的能力。PC 端通过串口发送控制命令，PS 端解析命令并写入控制字，PL 端根据控制字改变 HDMI 显示效果。

本实验不是普通可选扩展，而是第二周综合扩展的基础平台。学生需要先完成以下上位机控制显示能力，再在主目录 README 中选择 1 个综合扩展任务继续完成：

1. Sobel 二值化阈值控制。
2. 边缘彩色叠加显示控制。
3. 灰度图 / 边缘图 / 叠加图显示模式切换。

本实验不要求学生修改 PC 端 GUI。`host_camera_uart` 中的统一上位机已经兼容本实验：前面实验仍然使用图像发送功能，本实验额外使用显示控制功能。

## 1. 实验目标

完成本实验后，学生应能说明：

1. 图像数据和控制命令如何区分。
2. PS 端如何把上位机命令转换为控制字。
3. PL 端如何根据控制字选择 HDMI 显示模式。
4. PL 端如何根据阈值控制 Sobel 二值化边缘。
5. PL 端如何把边缘用彩色叠加到原图上。
6. 为什么控制功能要先仿真，再上板验证。

## 2. 数据流

```text
PC 图片 / 摄像头
    -> UART 图像帧
    -> PS 写入 AXI BRAM 图像区
    -> PL 读取图像并完成灰度转换和 Sobel
    -> HDMI 显示

PC 控制命令
    -> UART 命令
    -> PS 解析命令
    -> PS 写入 AXI BRAM 控制字
    -> PL 读取控制字
    -> 切换显示模式、阈值和彩色叠加开关
```

建议把 BRAM 分成两个区域：

```text
0x40000000 + 0x0000
    图像 framebuffer，128 x 72，每像素 32 bit，格式 0x00RRGGBB

0x40000000 + 0x9000
    控制字区域，例如 display_mode、threshold、overlay_enable
```

控制字地址只是建议。实际工程中必须确认 BRAM 空间足够，并且控制字地址不与图像区冲突。

## 3. 控制命令

本实验使用固定二进制控制帧，避免和图像二进制数据混淆：

```text
control frame: a5 5a cmd value
```

命令定义：

```text
cmd = 01
    value = 0: 原图
    value = 1: 灰度图
    value = 2: Sobel 二值化边缘图
    value = 3: 原图 + 彩色边缘叠加

cmd = 02
    value = 0..255: Sobel 二值化阈值

cmd = 03
    value = 0: 关闭彩色边缘叠加
    value = 1: 打开彩色边缘叠加
```

命令行上位机示例：

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --control-only --mode edge --threshold 80 --overlay off
python camera_uart_sender.py --port COM7 --baud 115200 --control-only --mode overlay --threshold 40 --overlay on
```

GUI 上位机中使用 `Display control for sobel_05` 区域设置 `Mode`、`Threshold` 和 `Overlay`，点击 `Send Control` 即可发送控制帧。

## 4. 控制字设计

本实验至少需要 3 个控制字：

```text
display_mode
    0: 原图
    1: 灰度图
    2: Sobel 二值化边缘图
    3: 原图 + 彩色边缘叠加

threshold
    Sobel 二值化阈值，建议初始值 80

overlay_enable
    0: 关闭彩色边缘叠加
    1: 打开彩色边缘叠加
```

PS 端负责写控制字，PL 端负责读取控制字并改变 HDMI 输出。

## 5. 主要修改范围

本实验从 `sobel_04_uart_sobel_hdmi` 派生工程，主要修改：

```text
PS 端 main.c
    增加控制命令解析
    增加 display_mode、threshold、overlay_enable 写入
    增加命令回显，打印当前控制状态

hdmi_bram_sobel_display.v
    增加控制字读取
    增加灰度图、边缘图、彩色叠加图输出选择
    增加 Sobel 阈值判断

仿真 testbench
    构造不同控制字
    验证不同模式、阈值和叠加开关下的 RGB 输出
```

不建议第一版同时修改 PC GUI、提高波特率或引入网络传输。

## 6. SDK 工程

本实验需要 PS 端 SDK 程序。当前目录已经包含完整 SDK 工作区：

```text
sobel_05_pc_control_display.sdk/
    top_hw_platform_0/
    ps_uart_control_bram_app_bsp/
    ps_uart_control_bram_app/
```

SDK 中真正要运行的应用工程是：

```text
sobel_05_pc_control_display.sdk/ps_uart_control_bram_app
```

应用源码位置：

```text
sobel_05_pc_control_display.sdk/ps_uart_control_bram_app/src/main.c
```

已经编译生成的 ELF 位置：

```text
sobel_05_pc_control_display.sdk/ps_uart_control_bram_app/Debug/ps_uart_control_bram_app.elf
```

外层目录：

```text
ps_uart_control_bram_app/src/main.c
```

是源码备份和重建 SDK 工程时的导入来源，不是 SDK GUI 中直接打开的工程。

如果 SDK 工程丢失，或 SDK 中只剩下 `top_hw_platform_0` 而没有应用工程，可以在本目录运行：

```bash
xsct rebuild_sdk_workspace.tcl
```

Windows 下如果 `xsct` 没有加入 PATH，可以运行：

```powershell
& 'C:\Xilinx\SDK\2017.4\bin\xsct.bat' rebuild_sdk_workspace.tcl
```

不要删除：

```text
sobel_05_pc_control_display.sdk/top_hw_platform_0
sobel_05_pc_control_display.sdk/ps_uart_control_bram_app_bsp
sobel_05_pc_control_display.sdk/ps_uart_control_bram_app
sobel_05_pc_control_display.sdk/top.hdf
ps_uart_control_bram_app
rebuild_sdk_workspace.tcl
```

其中 `top_hw_platform_0` 是硬件平台，`ps_uart_control_bram_app_bsp` 是 BSP，`ps_uart_control_bram_app` 是要下载运行的 PS 程序。SDK 自动生成 `top_hw_platform_1` 通常是重复导入硬件平台导致的；正常使用本目录已有的 `top_hw_platform_0` 即可。

## 7. 实验步骤

### 7.1 先复现 sobel_04

先完成 `sobel_04_uart_sobel_hdmi`，确认：

```text
PS 程序能接收 PC 图像
PL Sobel 能显示边缘图
HDMI 输出稳定
```

如果 `sobel_04` 没有跑通，不建议直接做本实验。

### 7.2 完成控制逻辑仿真

仿真必须先于上板完成。至少验证：

1. `display_mode = 1` 时输出灰度图。
2. `display_mode = 2` 时输出 Sobel 二值化边缘图。
3. `display_mode = 3` 或 `overlay_enable = 1` 时输出原图叠加彩色边缘。
4. 改变 `threshold` 后，边缘输出数量或边缘强度发生变化。

仿真可以使用固定像素输入，不要求完整模拟 UART 图像发送。报告中必须给出模式切换、阈值变化和叠加开关的波形或输出截图。

本目录提供了一个轻量级显示控制仿真：

```text
sim/display_control_model.v
sim/display_control_model_tb.v
```

命令行运行：

```bash
iverilog -g2012 -o sim/display_control_model_tb.vvp sim/display_control_model.v sim/display_control_model_tb.v
vvp sim/display_control_model_tb.vvp
```

该仿真只验证显示模式、阈值和叠加输出选择，不替代完整 Vivado 上板验证。

### 7.3 修改 PS 程序

在 PS 端 `main.c` 中增加命令解析，至少支持：

```text
a5 5a 01 mode
a5 5a 02 threshold
a5 5a 03 overlay_enable
```

PS 收到命令后，将控制值写入 BRAM 控制字区域，并通过串口回显当前状态。

### 7.4 修改 PL 显示逻辑

在 `hdmi_bram_sobel_display.v` 中增加显示模式选择：

```text
mode = 0
    输出原始 RGB

mode = 1
    输出灰度图

mode = 2
    输出 Sobel 二值化边缘图

mode = 3
    输出原图 + 彩色边缘叠加
```

阈值判断建议先做成简单逻辑：

```text
edge_bin = (edge_data >= threshold) ? 8'hff : 8'h00
```

彩色叠加建议先使用固定颜色，例如红色边缘：

```text
if (edge_bin)
    RGB = red
else
    RGB = original_rgb
```

### 7.5 上板验证

上板时建议流程：

1. 下载 bitstream。
2. 运行 PS 程序。
3. 用 PC 端工具发送图像。
4. 在 GUI 的 `Display control for sobel_05` 区域选择 `gray`，点击 `Send Control`，观察灰度图。
5. 选择 `edge`，观察 Sobel 二值化边缘图。
6. 选择 `overlay` 或勾选 `Overlay`，观察彩色边缘叠加图。
7. 分别设置阈值 `40`、`80`、`120`，比较阈值变化效果。

注意：同一个 COM 口不能同时被两个不同程序占用。GUI 连续发送图像时，可以直接在同一个 GUI 中修改 `Mode`、`Threshold`、`Overlay` 并点击 `Send Control`；控制帧会通过当前发送线程排队发出。

## 8. 验收标准

基础验收必须完成：

1. PC 命令能切换灰度图、Sobel 二值化边缘图、彩色边缘叠加图。
2. PC 命令能设置 Sobel 阈值，并能观察边缘效果变化。
3. PC 命令能打开或关闭彩色边缘叠加。
4. PS 串口能回显当前模式、阈值和叠加状态。
5. 提交控制逻辑仿真截图或波形截图。
6. 提交 HDMI 模式切换照片或视频截图。
7. 提交 Vivado 资源利用率和时序结果。

## 9. 报告要求

报告中至少说明：

1. 上位机命令格式。
2. PS 端命令解析流程。
3. 控制字地址和含义。
4. PL 端模式选择、阈值判断和彩色叠加逻辑。
5. 仿真结果。
6. 上板结果。
7. 与 `sobel_04` 基础边缘图的效果对比。

## 10. 后续扩展建议

完成本实验后，如果还需要进一步提高，可以选择：

| 选题 | 仿真要求 | 上板验收 |
| --- | --- | --- |
| 命令协议增强 | 验证错误命令不会破坏图像接收 | 错误命令能被忽略，合法命令稳定控制显示 |
| 更多显示模式 | 验证新增模式的 RGB 输出 | PC 命令可切换更多显示效果 |
| 阈值状态统计 | 仿真或软件测试边缘像素统计 | 串口能输出当前阈值和边缘像素数量 |

不建议把网络摄像头、DMA、Ethernet 或 PC GUI 修改作为本实验的基础要求。

## 11. 常见问题

### 11.1 命令和图像发送冲突

同一个串口不能同时被两个 PC 程序打开。使用 GUI 时，图像发送和控制命令已经集成在同一个程序中；不要再同时打开串口调试助手。

### 11.2 HDMI 模式没有变化

检查：

```text
PS 是否正确收到命令
PS 是否把控制字写入正确 BRAM 地址
PL 是否读取了控制字
显示模式选择逻辑是否接入 RGB 输出
bitstream 是否重新生成并下载
```

### 11.3 阈值命令没有效果

检查 Sobel 输出是否经过阈值判断。如果只是把 `edge_data` 直接复制到 RGB，阈值控制不会改变显示结果。

