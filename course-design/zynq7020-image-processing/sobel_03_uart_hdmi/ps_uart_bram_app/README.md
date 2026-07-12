# ps_uart_bram_app 说明

本目录保存 `sobel_03_uart_hdmi` 的 PS 端 C 程序源码备份，不是独立实验目录。完整实验步骤见上一级 `sobel_03_uart_hdmi/README.md`。

## 1. 程序功能

该程序运行在 ZYNQ PS 端，完成：

1. 初始化 PS UART，波特率固定为 `115200`。
2. 启动后先向 AXI BRAM 写入一张 `128 x 72` 测试图，便于验证 HDMI 显示链路。
3. 按约定协议接收 PC 端发送的 RGB888 图像。
4. 将接收到的图像写入 AXI BRAM，供 PL HDMI 逻辑读取显示。

## 2. 帧格式

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

## 3. BRAM 写入格式

```text
address = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

如果 `xparameters.h` 中没有 `XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR`，程序会退回使用 `0x40000000`。该地址应与 Vivado Block Design 中的 BRAM 地址保持一致。

## 4. SDK 使用说明

在 SDK 或 Vitis 中运行时，通常使用工程工作区里的：

```text
sobel_03_uart_hdmi.sdk/ps_uart_bram_app/src/main.c
```

如果需要从本目录恢复源码，可把：

```text
ps_uart_bram_app/src/main.c
```

复制到 SDK 应用工程的 `src/` 目录，然后重新：

```text
Re-generate BSP Sources
Clean Project
Build Project
Run As -> Launch on Hardware
```

## 5. 注意事项

默认优先使用 `XPAR_PS7_UART_1_DEVICE_ID`，因为当前黑金 PS 示例使用 UART1 MIO48/49。部分 BSP 会把 UART1 canonical 成 `XPAR_XUARTPS_0_DEVICE_ID`，程序中已经做了兼容。

如果硬件平台确实使用 UART0，可在应用编译选项中定义：

```text
-DUART_DEVICE_ID=XPAR_XUARTPS_0_DEVICE_ID
```
