# ps_uart_sobel_bram_app 说明

本目录保存 `sobel_04_uart_sobel_hdmi` 的 PS 端 C 程序源码备份，不是独立实验目录。完整实验步骤见上一级 `sobel_04_uart_sobel_hdmi/README.md`。

## 1. 程序功能

该程序运行在 ZYNQ PS 端，完成：

1. 初始化 PS UART，波特率固定为 `115200`。
2. 启动后先向 AXI BRAM 写入一张 `128 x 72` 测试图。
3. 按约定协议接收 PC 端发送的 RGB888 图像。
4. 将原始 RGB 图像写入 AXI BRAM。

Sobel 运算不在 PS 程序中完成，而是在 PL 端 `hdmi_bram_sobel_display.v` 中完成。

## 2. 串口配置

```text
baud      = 115200
data bits = 8
parity    = None
stop bits = 1
flow ctrl = None
```

## 3. 帧格式

```text
frame header: 55 aa width_l width_h height_l height_h 18
line header : 33 cc row_l row_h
pixels      : R G B, repeated 128 times per row
```

只接收以下格式：

```text
width  = 128
height = 72
format = 0x18, RGB888
```

## 4. BRAM 写入格式

```text
address = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

如果 `xparameters.h` 中没有 `XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR`，程序会退回使用 `0x40000000`。

## 5. 预期串口输出

运行成功后，串口应看到：

```text
PS UART PL Sobel HDMI display
BRAM base: 0x40000000, baud: 115200, image: 128x72
waiting for frame header
```

## 6. SDK 使用说明

在 SDK 或 Vitis 中运行时，通常使用工程工作区里的：

```text
sobel_04_uart_sobel_hdmi.sdk/ps_uart_bram_app/src/main.c
```

如果需要从本目录恢复源码，可把：

```text
ps_uart_sobel_bram_app/src/main.c
```

复制到 SDK 应用工程的 `src/` 目录，然后重新生成 BSP、编译并运行。
