# Sobel RGB888 Iverilog Simulation

This directory contains a pure Verilog simulation path for receiving an RGB888 image over UART, converting it to grayscale, running Sobel edge detection, and producing a display-ready grayscale RGB stream.

## Protocol

The UART byte stream uses this binary frame format:

```text
55 aa
width_l width_h
height_l height_h
18

33 cc row_l row_h
R G B ... R G B

33 cc row_l row_h
R G B ... R G B
```

- `0x18` means RGB888.
- RGB pixels are sent in raster order, one pixel as `R, G, B`.
- Image data is split into fixed-size line packets, so the FPGA can process rows as they arrive instead of storing a full frame.
- There is no retransmission or mandatory checksum. If the receiver loses sync, it scans for the next frame or line sync word and resumes from the next valid line.
- `row_l row_h` is used to place each received line. A bad line id is discarded.

## Run

```sh
make sim
```

The default simulation generates a `128x72` test image at `data/input_rgb.hex`, runs the UART/Sobel pipeline, and writes:

- `data/sobel_out.pgm`: grayscale Sobel edge image.
- `data/input_rgb.png`: directly viewable RGB input image.
- `data/sobel_out.png`: directly viewable Sobel edge image.
- `build/sobel_system_tb.vcd`: waveform for GTKWave.

If the simulation outputs already exist, regenerate only the PNG files with:

```sh
make images
```

This writes `data/input_rgb.png` and `data/sobel_out.png`.

Use different dimensions with:

```sh
make sim WIDTH=8 HEIGHT=8
make sim WIDTH=640 HEIGHT=480 BAUD_RATE=1000000 CLK_FREQ=12000000
```

The RTL module defaults remain `50 MHz` and `115200` baud for board-style use. The Makefile uses faster simulation parameters by default so the full UART byte stream completes quickly under Iverilog.

The HDMI physical layer is intentionally outside this Iverilog test. The simulated video output is the HDMI front-end pixel stream with `R=G=B=edge_data`.
