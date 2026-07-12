# ps_uart_control_bram_app 说明

本目录保存 `sobel_05_pc_control_display` 的 PS 端 C 程序源码备份，不是独立实验目录。

完整 SDK 工程位于：

```text
sobel_05_pc_control_display.sdk/ps_uart_control_bram_app
```

如果 SDK 应用工程丢失，可以在上一级目录运行：

```bash
xsct rebuild_sdk_workspace.tcl
```

脚本会使用本目录的 `src/main.c` 重新创建 SDK 应用工程。

## 程序功能

该程序运行在 ZYNQ PS 端，完成：

1. 初始化 PS UART，波特率固定为 `115200`。
2. 启动后先向 AXI BRAM 写入一张 `128 x 72` 测试图。
3. 接收 PC 端发送的 RGB888 图像帧，并写入 AXI BRAM 图像区。
4. 接收 PC 端发送的控制帧，并写入 AXI BRAM 控制字区。

Sobel、阈值判断、灰度显示、彩色叠加和 HDMI 输出都在 PL 端 `hdmi_bram_sobel_display.v` 中完成。

## 串口配置

```text
baud      = 115200
data bits = 8
parity    = None
stop bits = 1
flow ctrl = None
```

## 图像帧格式

```text
frame header: 55 aa width_l width_h height_l height_h 18
line header : 33 cc row_l row_h
pixels      : R G B, repeated 128 times per row
```

只接收以下图像格式：

```text
width  = 128
height = 72
format = 0x18, RGB888
```

图像写入格式：

```text
address = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

## 控制帧格式

```text
a5 5a cmd value
```

命令定义：

```text
cmd = 01
    value = 0 原图
    value = 1 灰度图
    value = 2 Sobel 二值化边缘图
    value = 3 原图 + 彩色边缘叠加

cmd = 02
    value = 0..255 Sobel 二值化阈值

cmd = 03
    value = 0 关闭彩色叠加
    value = 1 打开彩色叠加
```

控制字写入地址：

```text
mode      = base + 0x9000
threshold = base + 0x9004
overlay   = base + 0x9008
```

如果 `xparameters.h` 中没有 `XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR`，程序会退回使用 `0x40000000`。

## 预期串口输出

运行成功后，串口应看到：

```text
PS UART PL Control HDMI display
BRAM base: 0x40000000, baud: 115200, image: 128x72
control frame: a5 5a cmd value, cmd 1=mode 2=threshold 3=overlay
control: mode=2 threshold=80 overlay=0
waiting for frame or control header
```

收到控制命令后会回显当前状态：

```text
control: mode=3 threshold=80 overlay=1
```
