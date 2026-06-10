# Sobel RGB888 RTL Simulation

This directory is the pre-lab pure RTL simulation package. It verifies the
UART image receive path, RGB-to-grayscale conversion, Sobel edge detection, and
display-side grayscale pixel stream before the design is moved into Vivado.

## Directory layout

```text
sobel_00_rtl_sim/
├── Makefile
├── README.md
├── data/
│   └── input_rgb.hex
├── rtl/
│   ├── image_frame_rx.v
│   ├── rgb_to_gray.v
│   ├── sobel_core.v
│   ├── sobel_system.v
│   ├── uart_rx.v
│   └── video_stream_model.v
├── tb/
│   └── sobel_system_tb.v
└── tools/
    ├── convert_images.py
    └── gen_input_rgb.py
```

`data/` is reserved for fixed input samples. Simulation products such as
compiled `.vvp` files, waveforms, PGM images, and generated PNG previews are
written to `build/` and ignored by Git.

## Relationship to the Vivado Labs

This pre-lab simulation verifies the algorithm and stream protocol before the
Vivado projects are opened:

- `rtl/rgb_to_gray.v` is the same module used by `sobel_02_hdmi_sobel` and
  `sobel_04_uart_sobel_hdmi`.
- `rtl/sobel_core.v` is the same module used by `sobel_02_hdmi_sobel` and
  `sobel_04_uart_sobel_hdmi`.
- `rtl/uart_rx.v`, `rtl/image_frame_rx.v`, `rtl/sobel_system.v`, and
  `rtl/video_stream_model.v` form a pure RTL verification harness. In the
  Zynq labs, the PS receives UART data, writes RGB888 pixels into AXI BRAM, and
  the PL reads BRAM before feeding `rgb_to_gray` and `sobel_core`.

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

Windows PowerShell with Icarus Verilog installed in WSL:

```powershell
.\run_sim.ps1
# or explicitly:
.\run_sim.ps1 -UseWsl
```

Windows PowerShell with native Icarus Verilog:

```powershell
.\run_sim.ps1
```

Linux, macOS, MSYS2, or Git Bash:

```sh
make sim
```

The default simulation uses the `128x72` fixed sample at `data/input_rgb.hex`,
runs the UART/Sobel pipeline, and writes:

- `build/sobel_out.pgm`: grayscale Sobel edge image.
- `build/input_rgb.png`: directly viewable RGB input image.
- `build/sobel_out.png`: directly viewable Sobel edge image.
- `build/sobel_system_tb.vcd`: waveform for GTKWave.

If the simulation outputs already exist, regenerate only the PNG files with:

```sh
make images
```

This writes `build/input_rgb.png` and `build/sobel_out.png`.

Use different dimensions with:

```powershell
.\run_sim.ps1 -Width 8 -Height 8
.\run_sim.ps1 -Width 640 -Height 480 -BaudRate 1000000 -ClkFreq 12000000
```

or:

```sh
make sim WIDTH=8 HEIGHT=8
make sim WIDTH=640 HEIGHT=480 BAUD_RATE=1000000 CLK_FREQ=12000000
```

For `128x72`, the Makefile keeps using `data/input_rgb.hex` as the stable
course sample. Other dimensions generate their temporary RGB hex input under
`build/`.

The RTL module defaults remain `50 MHz` and `115200` baud for board-style use. The Makefile uses faster simulation parameters by default so the full UART byte stream completes quickly under Iverilog.

The HDMI physical layer is intentionally outside this Iverilog test. The simulated video output is the HDMI front-end pixel stream with `R=G=B=edge_data`.
