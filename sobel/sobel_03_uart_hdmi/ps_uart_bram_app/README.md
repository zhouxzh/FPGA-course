# PS UART BRAM App

这个目录是第三步的 PS 端应用源码。工程在 SDK/Vitis 中新建，`main.c` 复制到应用的 `src/` 目录即可。

## 功能

- 使用 `XUartPs` 初始化 PS 板载 UART。
- UART 波特率固定为 `115200`。
- 启动后先写一个 `128x72` 测试图到 AXI BRAM，便于验证 HDMI 显示链路。
- 按协议接收 PC 端发送的 RGB888 图像，并写入 AXI BRAM：

```text
frame header: 55 aa width_l width_h height_l height_h 18
line header : 33 cc row_l row_h
pixels      : R G B, repeated 128 times per row
```

BRAM 写入格式：

```text
address = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

## 注意

默认优先使用 `XPAR_PS7_UART_1_DEVICE_ID`，因为仓库中的黑金 PS 示例使用 UART1 MIO48/49。注意 Xilinx BSP 里这个 UART1 也可能被 canonical 成 `XPAR_XUARTPS_0_DEVICE_ID`，程序已经做了兼容。

如果你的硬件平台确实使用 UART0，请在应用编译选项中定义：

```text
-DUART_DEVICE_ID=XPAR_XUARTPS_0_DEVICE_ID
```

如果 `xparameters.h` 中没有 `XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR`，程序会退回使用 `0x40000000`。这应与 `create_ps_uart_bram_hdmi_bd.tcl` 中分配的 BRAM 地址保持一致。
