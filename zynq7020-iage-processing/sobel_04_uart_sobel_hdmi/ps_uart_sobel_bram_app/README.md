# PS UART PL Sobel BRAM App

This is the PS-side application for `sobel_04_uart_sobel_hdmi`.

The PS receives `128x72` RGB888 frames from UART and writes the raw RGB image into AXI BRAM. The Sobel operation is done in PL by `hdmi_bram_sobel_display.v`, which reads the BRAM frame and displays the edge image over HDMI.

## UART

```text
baud      = 115200
data bits = 8
parity    = None
stop bits = 1
flow ctrl = None
```

## Frame Protocol

```text
frame header: 55 aa width_l width_h height_l height_h 18
line header : 33 cc row_l row_h
pixels      : R G B, repeated 128 times per row
```

Only this format is accepted:

```text
width  = 128
height = 72
format = 0x18, RGB888
```

## BRAM Write Format

```text
address = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + ((y * 128 + x) << 2)
data    = 0x00RRGGBB
```

If `xparameters.h` does not define `XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR`, the program falls back to `0x40000000`.

## Expected Serial Output

```text
PS UART PL Sobel HDMI display
BRAM base: 0x40000000, baud: 115200, image: 128x72
waiting for frame header
```
