# Host Camera UART Sender

This directory contains the PC-side sender for `sobel_03_uart_hdmi`.
It captures an image from a USB camera or reads a still image, resizes it to
`128x72`, converts it to RGB888, and sends it to the Zynq PS UART.

## Requirements

- Python 3.13
- A working USB camera, or an image file
- The board UART app running at `115200` baud

## Install Anaconda

1. Download Anaconda from the official website:

   ```text
   https://www.anaconda.com/download
   ```

2. Install it with the default options. On Windows, open **Anaconda Prompt** after installation.

3. Check that `conda` is available:

   ```bash
   conda --version
   ```

## Create The Conda Environment

Create a virtual environment named `fpga`:

```bash
conda create -n fpga python=3.13 -y
```

Activate it:

```bash
conda activate fpga
```

Go to this directory:

```bash
cd D:\Github\FPGA-course\sobel\host_camera_uart
```

Install Python packages in the `fpga` environment:

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Check the installation:

```bash
python -c "import cv2, numpy, serial; print('ok')"
```

Every time before running the sender, activate the environment first:

```bash
conda activate fpga
```

## Serial Settings

Use these settings on both the FPGA PS app and the PC sender:

```text
baud      = 115200
data bits = 8
parity    = none
stop bits = 1
flow ctrl = none
```

At `115200` baud, one `128x72` RGB888 frame takes more than 2 seconds to send.
Use a low frame rate first.

## Run

Windows example:

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --preview
```

Linux example:

```bash
python3 camera_uart_sender.py --port /dev/ttyUSB0 --baud 115200 --camera 0 --fps 0.2 --preview
```

Send one still image:

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --image test.jpg --once --preview
```

If the image is unstable, add a small delay after each line:

```bash
python camera_uart_sender.py --port COM7 --baud 115200 --camera 0 --fps 0.2 --line-delay 0.001 --preview
```

## Protocol

Frame header:

```text
55 aa width_l width_h height_l height_h 18
```

Line packet:

```text
33 cc row_l row_h
R G B, repeated 128 times
```

Default image format:

```text
width  = 128
height = 72
format = 0x18, RGB888
```

## Notes

- Close any serial terminal before running this script. Only one program can open the same COM port.
- If the PS UART terminal prints `waiting for frame header`, the board app is running and waiting for this script.
- At `115200` baud, use `--fps 0.2` or lower for the first test.
