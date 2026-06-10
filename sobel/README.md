# Sobel HDMI 实验路线

这个目录用于在黑金 ZYNQ7020 开发板上逐步完成一个固定图片的 HDMI 显示、Sobel 边缘检测显示，以及 PS UART 摄像头图像传输到 HDMI 显示实验。当前路线分三步：

1. `sobel_01_hdmi_pattern`：已经把 `128x72` RGB 图片正常显示到 `1280x720` HDMI 输出。
2. `sobel_02_hdmi_sobel`：新建一个工程，读取同一张图片，在 PL 中完成灰度转换和 Sobel 运算，再把边缘结果放大显示到 HDMI。
3. `sobel_03_uart_hdmi`：使用 PS 板载 UART 接收 PC 摄像头图像，通过 AXI BRAM 共享帧缓存，PL HDMI 直接显示接收到的原图。

## 目录

```text
sobel/
├── README.md
├── iverilog/
│   ├── data/
│   │   └── input_rgb.hex
│   └── rtl/
│       ├── rgb_to_gray.v
│       └── sobel_core.v
└── sobel_01_hdmi_pattern/
    ├── sobel_01_hdmi_pattern.xpr
    └── sobel_01_hdmi_pattern.srcs/
        ├── constrs_1/new/hdmi_out_test.xdc
        └── sources_1/
            ├── ip/
            │   ├── rgb2dvi_0/
            │   └── video_clock/
            └── new/
                ├── top.v
                └── hdmi_image_display.v
├── sobel_02_hdmi_sobel/
├── sobel_03_uart_hdmi/
│   ├── create_ps_uart_bram_hdmi_bd.tcl
│   ├── ps_uart_bram_app/
│   └── sobel_03_uart_hdmi.srcs/sources_1/new/
│       ├── hdmi_bram_display.v
│       └── hdmi_pl_top.v
└── host_camera_uart/
    ├── camera_uart_sender.py
    ├── requirements.txt
    └── README.md
```

`iverilog/data/input_rgb.hex` 是固定输入图片，大小为 `128x72`，每个像素 3 个字节，顺序是 `R, G, B`。

```text
128 * 72 * 3 = 27648
```

## 第 1 步：HDMI 固定图片显示

第 1 步工程路径：

```text
sobel/sobel_01_hdmi_pattern/sobel_01_hdmi_pattern.xpr
```

这个工程已经不是彩条显示，而是固定图片显示。主要源码如下：

```text
top.v
hdmi_image_display.v
hdmi_out_test.xdc
video_clock IP
rgb2dvi_0 IP
```

### 第 1 步数据流

```text
sys_clk
  |
  v
video_clock
  |-- video_clk    = 720p pixel clock, about 74.25 MHz
  `-- video_clk_5x = TMDS serial clock, about 371.25 MHz
        |
        v
hdmi_image_display
  |
  |-- hs / vs / de
  `-- rgb_r / rgb_g / rgb_b
        |
        v
rgb2dvi_0
        |
        v
TMDS HDMI output
```

### `top.v`

`top.v` 保持 HDMI 顶层连接，例化三个模块：

- `hdmi_image_display`：产生 `1280x720` 视频时序，并输出图片 RGB。
- `video_clock`：产生 HDMI 像素时钟和 5 倍串行时钟。
- `rgb2dvi_0`：把 RGB888、`de`、`hs`、`vs` 转成 HDMI TMDS 信号。

顶层端口仍然是：

```verilog
input        sys_clk;
output       hdmi_oen;
output       TMDS_clk_n;
output       TMDS_clk_p;
output [2:0] TMDS_data_n;
output [2:0] TMDS_data_p;
```

### `hdmi_image_display.v`

这个模块完成两件事：

1. 产生 `1280x720` HDMI 显示时序。
2. 把内置的 `128x72` 图片按 `10x10` 放大显示。

当前时序参数：

```text
H_ACTIVE = 1280
H_FP     = 110
H_SYNC   = 40
H_BP     = 220
H_TOTAL  = 1650

V_ACTIVE = 720
V_FP     = 5
V_SYNC   = 5
V_BP     = 20
V_TOTAL  = 750
```

输入图片大小：

```text
IMG_WIDTH  = 128
IMG_HEIGHT = 72
SCALE_X    = 1280 / 128 = 10
SCALE_Y    = 720  / 72  = 10
```

显示区域中的坐标映射：

```verilog
image_x = active_x / 10;
image_y = active_y / 10;
image_addr = image_y * 128 + image_x;
```

图片数据来自 `input_rgb.hex`。当前已经把每 3 个字节合并为一个 `24'hRRGGBB`，写入 `image_rom_128x72` 的 `image_mem[0:9215]` 中。

### 第 1 步验收标准

下载 bitstream 后，HDMI 显示器应能看到稳定的固定图片：

- 显示器能识别 `1280x720` 输入。
- 图像铺满有效显示区域。
- 每个原始像素被放大成 `10x10`。
- 图像不应再显示 color bar。

如果显示器无信号，优先检查：

1. `video_clock` 是否正常 locked。
2. `video_clk` 和 `video_clk_5x` 是否分别约为 `74.25 MHz` 和 `371.25 MHz`。
3. `hdmi_out_test.xdc` 中 TMDS 管脚是否和开发板原理图一致。
4. `rgb2dvi_0` 的 `PixelClk` 和 `SerialClk` 是否接反。
5. `hdmi_oen` 是否正确连接。

## 第 2 步：新建工程做 Sobel 后 HDMI 显示

第 2 步不要直接覆盖第 1 步工程。建议新建或复制一个工程：

```text
sobel_02_hdmi_sobel
```

目标是：仍然使用第 1 步的那张 `128x72` 图片，但显示内容从原始 RGB 图片改为 Sobel 边缘图。

推荐最终显示链路：

```text
image_rom_128x72
        |
        v
rgb_to_gray
        |
        v
sobel_core
        |
        v
edge_mem_128x72
        |
        v
10x HDMI display scale
        |
        v
rgb2dvi_0
        |
        v
HDMI monitor
```

这里建议增加一个 `edge_mem_128x72`，而不是把 Sobel 输出直接接到 HDMI。原因是：

- `sobel_core` 输出有流水线延迟。
- Sobel 运算基于 `128x72` 原图，而 HDMI 输出是 `1280x720`。
- HDMI 显示每个低分辨率像素要重复 `10x10` 次。
- 使用边缘结果缓存后，Sobel 运算和 HDMI 读取可以解耦，显示逻辑更简单。

### 第 2 步工程创建

推荐做法：

1. 保留 `sobel_01_hdmi_pattern` 作为已经验证通过的 HDMI 基线工程。
2. 复制整个 `sobel_01_hdmi_pattern` 目录，命名为 `sobel_02_hdmi_sobel`。
3. 打开复制后的 `.xpr`。
4. 在 Vivado 中另存或重命名工程，确保工程名变为 `sobel_02_hdmi_sobel`。
5. 清理旧的综合和实现结果，重新运行综合和实现。

如果不想复制工程，也可以新建 RTL Project，然后导入第 1 步工程中的这些文件：

```text
sources_1/new/top.v
sources_1/new/hdmi_image_display.v
sources_1/ip/video_clock/video_clock.xci
sources_1/ip/rgb2dvi_0/rgb2dvi_0.xci
constrs_1/new/hdmi_out_test.xdc
```

确认第 2 步工程能在不改功能的情况下重新生成 bitstream，并仍然显示原始图片。这个动作很重要，用来证明新工程复制没有破坏 HDMI 基线。

### 添加 Sobel 相关 RTL

从仿真目录加入两个已经验证过的数据处理模块：

```text
sobel/iverilog/rtl/rgb_to_gray.v
sobel/iverilog/rtl/sobel_core.v
```

`rgb_to_gray.v` 接口：

```verilog
rgb_valid, r, g, b, x, y
    -> gray_valid, gray, gray_x, gray_y
```

`sobel_core.v` 接口：

```verilog
frame_start, gray_valid, gray, gray_x, gray_y
    -> edge_valid, edge_data, edge_x, edge_y, edge_frame_done
```

参数保持：

```verilog
.WIDTH(128),
.HEIGHT(72)
```

### 新建显示处理模块

把第 1 步的 `hdmi_image_display.v` 复制一份，建议命名为：

```text
hdmi_sobel_display.v
```

模块端口保持和 `hdmi_image_display` 一致，这样 `top.v` 只需要替换模块名：

```verilog
module hdmi_sobel_display(
    input clk,
    input rst,
    output hs,
    output vs,
    output de,
    output [7:0] rgb_r,
    output [7:0] rgb_g,
    output [7:0] rgb_b
);
```

内部保留第 1 步已经验证过的 HDMI 时序逻辑：

```text
h_cnt / v_cnt
hs_reg / vs_reg / de_reg
active_x / active_y
image_x = active_x / 10
image_y = active_y / 10
```

然后把原来直接输出原图 RGB 的逻辑，改为：

1. 上电后先扫描 `image_rom_128x72`。
2. 每个时钟输出一个原图像素给 `rgb_to_gray`。
3. 灰度结果送给 `sobel_core`。
4. `sobel_core.edge_valid` 有效时，把 `edge_data` 写入 `edge_mem_128x72`。
5. `edge_frame_done` 后置位 `sobel_done`。
6. HDMI 显示阶段读取 `edge_mem_128x72`，把 `edge_data` 同时接到 `R/G/B`。

### Sobel 预处理状态机

建议在 `hdmi_sobel_display.v` 内增加一个简单状态机：

```text
IDLE
  |
  v
RUN_SOBEL
  |
  v
WAIT_DONE
  |
  v
DISPLAY
```

状态含义：

- `IDLE`：复位后初始化计数器。
- `RUN_SOBEL`：从 `image_rom_128x72` 顺序读取 `128*72` 个像素。
- `WAIT_DONE`：等待 `sobel_core.edge_frame_done`。
- `DISPLAY`：HDMI 持续读取 `edge_mem_128x72` 显示边缘图。

扫描原图时使用两个计数器：

```verilog
reg [6:0] src_x;
reg [6:0] src_y;
```

原图地址：

```verilog
src_addr = src_y * 128 + src_x;
```

由于宽度是 128，可以用移位拼接避免乘法：

```verilog
src_addr = {src_y, 7'b0} + {7'd0, src_x};
```

`image_rom_128x72` 是同步 ROM，地址给出后下一拍才得到 `image_pixel`。因此要把 `src_x/src_y` 延迟一拍后再和 RGB 一起送给 `rgb_to_gray`：

```verilog
src_x_d0 <= src_x;
src_y_d0 <= src_y;
rgb_valid <= src_valid_d0;
```

送入灰度模块：

```verilog
rgb_to_gray u_rgb_to_gray (
    .clk(clk),
    .rst_n(~rst),
    .rgb_valid(rgb_valid),
    .r(image_pixel[23:16]),
    .g(image_pixel[15:8]),
    .b(image_pixel[7:0]),
    .x({9'd0, src_x_d0}),
    .y({9'd0, src_y_d0}),
    .gray_valid(gray_valid),
    .gray(gray),
    .gray_x(gray_x),
    .gray_y(gray_y)
);
```

`frame_start` 在开始扫描第一帧前拉高一个时钟：

```verilog
frame_start <= (state == IDLE);
```

### 例化 Sobel 核

```verilog
sobel_core #(
    .WIDTH(128),
    .HEIGHT(72)
) u_sobel_core (
    .clk(clk),
    .rst_n(~rst),
    .frame_start(frame_start),
    .gray_valid(gray_valid),
    .gray(gray),
    .gray_x(gray_x),
    .gray_y(gray_y),
    .edge_valid(edge_valid),
    .edge_data(edge_data),
    .edge_x(edge_x),
    .edge_y(edge_y),
    .edge_frame_done(edge_frame_done)
);
```

### 边缘结果缓存

增加一个 `128x72` 的 8 bit RAM：

```verilog
reg [7:0] edge_mem [0:9215];
```

写地址：

```verilog
edge_wr_addr = {edge_y[6:0], 7'b0} + {7'd0, edge_x[6:0]};
```

写入：

```verilog
always @(posedge clk) begin
    if (edge_valid)
        edge_mem[edge_wr_addr] <= edge_data;
end
```

Sobel 结束：

```verilog
always @(posedge clk or posedge rst) begin
    if (rst)
        sobel_done <= 1'b0;
    else if (edge_frame_done)
        sobel_done <= 1'b1;
end
```

### HDMI 读取边缘图

显示时仍然按第 1 步的 `10x10` 放大方式读取：

```verilog
disp_x = active_x / 10;
disp_y = active_y / 10;
edge_rd_addr = disp_y * 128 + disp_x;
```

同样可以写成：

```verilog
edge_rd_addr = {disp_y, 7'b0} + {7'd0, disp_x};
```

同步 RAM 读出后输出灰度 RGB：

```verilog
assign rgb_r = (de_reg_d0 && sobel_done) ? edge_pixel : 8'h00;
assign rgb_g = (de_reg_d0 && sobel_done) ? edge_pixel : 8'h00;
assign rgb_b = (de_reg_d0 && sobel_done) ? edge_pixel : 8'h00;
```

如果希望在 Sobel 计算完成前显示原图，也可以在 `sobel_done == 0` 时临时输出 `image_pixel`。为了调试简单，建议先显示黑屏，等 `sobel_done` 后显示边缘图。

### 修改 `top.v`

第 2 步中 `top.v` 不需要改 HDMI IP 连接，只需要把显示模块从：

```verilog
hdmi_image_display hdmi_image_display_m0(
```

改为：

```verilog
hdmi_sobel_display hdmi_sobel_display_m0(
```

端口连接保持不变：

```verilog
.clk(video_clk),
.rst(1'b0),
.hs(video_hs),
.vs(video_vs),
.de(video_de),
.rgb_r(video_r),
.rgb_g(video_g),
.rgb_b(video_b)
```

`video_clock`、`rgb2dvi_0` 和 `hdmi_out_test.xdc` 不要改。这样如果第 2 步显示异常，可以快速判断问题在 Sobel 数据通路，而不是 HDMI 输出链路。

### Vivado 操作顺序

1. 打开或新建 `sobel_02_hdmi_sobel`。
2. 确认工程仍能显示第 1 步原始图片。
3. 添加 `rgb_to_gray.v` 和 `sobel_core.v`。
4. 新建 `hdmi_sobel_display.v`。
5. 在 `hdmi_sobel_display.v` 中保留第 1 步 HDMI 时序。
6. 添加原图扫描状态机。
7. 例化 `rgb_to_gray`。
8. 例化 `sobel_core`。
9. 添加 `edge_mem` 写入逻辑。
10. 添加 HDMI 读取 `edge_mem` 的显示逻辑。
11. 修改 `top.v`，把显示模块换成 `hdmi_sobel_display`。
12. 在 `Sources` 中确认 `top` 仍然是顶层。
13. 点击 `Run Synthesis`。
14. 综合通过后点击 `Run Implementation`。
15. 实现通过后点击 `Generate Bitstream`。
16. 下载到开发板，观察 HDMI 显示结果。

### 建议先仿真再上板

上板前建议先对 `hdmi_sobel_display` 做一个很小的 RTL 仿真：

- 时钟跑几十万个周期。
- 检查 `sobel_done` 是否最终变为 1。
- 检查 `edge_valid` 是否出现。
- 检查 `edge_mem` 是否被写入。

重点观察信号：

```text
state
src_x
src_y
rgb_valid
gray_valid
edge_valid
edge_data
edge_x
edge_y
edge_frame_done
sobel_done
edge_wr_addr
edge_rd_addr
video_de
```

### 第 2 步验收标准

下载 bitstream 后，HDMI 显示器应显示固定图片的 Sobel 边缘结果：

- 背景和纯色区域接近黑色。
- 图像轮廓、颜色变化明显的位置显示为白色或灰色边缘。
- 边框区域为黑色。
- 显示稳定，无错行、撕裂或周期性闪烁。

如果显示全黑：

1. 先把 `top.v` 改回 `hdmi_image_display`，确认 HDMI 基线仍然正常。
2. 用 ILA 看 `sobel_done` 是否置位。
3. 用 ILA 看 `edge_valid` 是否出现。
4. 检查 `frame_start` 是否只在 Sobel 开始时拉高一个时钟。
5. 检查 `src_x/src_y` 是否完整扫描到 `127/71`。
6. 检查 `rgb_to_gray.rst_n` 和 `sobel_core.rst_n` 是否没有一直复位。

如果边缘图错位：

1. 检查同步 ROM 读出延迟是否补偿。
2. 检查 `src_x/src_y` 是否和 `image_pixel` 同拍。
3. 检查 `edge_x/edge_y` 写入地址是否使用 Sobel 输出坐标，而不是输入坐标。
4. 检查 HDMI 读 `edge_mem` 时是否也延迟了 `de`。

如果综合资源过高：

1. 确认 `image_mem` 和 `edge_mem` 被推断为 block RAM。
2. 给 RAM 增加属性：

```verilog
(* ram_style = "block" *) reg [7:0] edge_mem [0:9215];
```

3. 如果 `/ 10` 产生资源过多，可以改成 `0..9` 的重复计数器生成 `disp_x/disp_y`。

## 后续扩展

## 第 3 步：PS UART 摄像头图像传输到 HDMI

第 3 步工程路径：

```text
sobel/sobel_03_uart_hdmi/sobel_03_uart_hdmi.xpr
```

目标是：

```text
PC camera
  |
  v
OpenCV resize to 128x72 RGB888
  |
  v
PS UART, 1000000 baud
  |
  v
PS C program parses frame protocol
  |
  v
AXI BRAM, 0x00RRGGBB per 32-bit word
  |
  v
PL hdmi_bram_display reads BRAM Port B
  |
  v
1280x720 HDMI, 10x scale
```

第三步只显示原图，不做 Sobel。Sobel 会在第四步再接到 BRAM 输入之后合并。

### 硬件结构

`sobel_03_uart_hdmi` 保留第 1 步已经验证过的 HDMI IP：

```text
video_clock
rgb2dvi_0
hdmi_out_test.xdc
```

新增 PL 源码：

```text
hdmi_bram_display.v
hdmi_pl_top.v
```

新增 BD 生成脚本：

```text
create_ps_uart_bram_hdmi_bd.tcl
```

Block Design 结构：

```text
processing_system7_0 M_AXI_GP0
  |
  v
AXI Interconnect / SmartConnect
  |
  v
axi_bram_ctrl_0
  |
  v
blk_mem_gen_0 Port A

blk_mem_gen_0 Port B
  |
  v
hdmi_pl_top / hdmi_bram_display
```

BRAM 按 64KB 配置。实际图像只需要：

```text
128 * 72 * 4 = 36864 bytes
```

每个像素占一个 32-bit word：

```text
0x00RRGGBB
```

PS 写地址：

```c
base + ((y * 128 + x) << 2)
```

PL 读地址：

```verilog
bram_addr = {16'd0, (image_y * 128 + image_x), 2'b00};
```

其中：

```verilog
image_x = active_x / 10;
image_y = active_y / 10;
```

### 生成 Block Design

打开 `sobel_03_uart_hdmi.xpr` 后，在 Vivado Tcl Console 中执行：

```tcl
cd D:/Github/FPGA-course/sobel/sobel_03_uart_hdmi
source create_ps_uart_bram_hdmi_bd.tcl
```

脚本会创建 `ps_uart_bram_hdmi` block design，并设置 `ps_uart_bram_hdmi_wrapper` 为工程顶层。外部 HDMI 端口名保持：

```text
sys_clk
hdmi_oen
TMDS_clk_n
TMDS_clk_p
TMDS_data_n[2:0]
TMDS_data_p[2:0]
```

这样现有 `hdmi_out_test.xdc` 可以继续使用。PS 的 `DDR` 和 `FIXED_IO` 由 Zynq PS block design 导出，不需要写普通 PL 管脚约束。

脚本默认启用 UART1 MIO48/49，这和仓库中已有黑金 PS 示例一致。如果你的板卡 preset 使用不同 UART，需要在 Vivado 中打开 `processing_system7_0` 检查 UART MIO，并在 SDK/Vitis 端同步选择正确的 `XPAR_XUARTPS_*_DEVICE_ID`。

### PS 端应用

源码路径：

```text
sobel/sobel_03_uart_hdmi/ps_uart_bram_app/src/main.c
```

在 SDK/Vitis 中创建 standalone C 应用，把 `main.c` 放到应用 `src/` 目录。程序会：

1. 初始化 `XUartPs`，波特率 `1000000`。
2. 先向 BRAM 写一个 `128x72` 测试图。
3. 循环等待 PC 端发送图像帧。
4. 每接收一个像素，立即写入 AXI BRAM。

接收协议：

```text
frame header: 55 aa width_l width_h height_l height_h 18
line header : 33 cc row_l row_h
pixels      : R G B, repeated 128 times per row
```

只接受：

```text
width  = 128
height = 72
format = 0x18
```

如果 `xparameters.h` 里没有 `XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR`，程序会退回使用 `0x40000000`。这个地址应和 BD 中分配给 `axi_bram_ctrl_0` 的地址一致。

### 上位机程序

路径：

```text
sobel/host_camera_uart/
```

安装依赖：

```bash
pip install -r requirements.txt
```

Windows 运行示例：

```bash
python camera_uart_sender.py --port COM5 --baud 1000000 --camera 0 --fps 2 --preview
```

Linux 运行示例：

```bash
python3 camera_uart_sender.py --port /dev/ttyUSB0 --baud 1000000 --camera 0 --fps 2 --preview
```

程序会读取摄像头 BGR 图像，缩放到 `128x72`，转换为 RGB，然后逐行发送。默认 `2 fps`，先保证稳定；如果画面花屏，先降到 `1 fps` 或增加行间延时：

```bash
python camera_uart_sender.py --port COM5 --fps 1 --line-delay 0.001
```

### 第 3 步调试顺序

1. 只下载 bitstream，不运行 PS 应用：HDMI 应稳定输出黑屏或 BRAM 初始内容，显示器识别 `1280x720`。
2. 运行 PS 应用，但不运行 PC 上位机：PS 会先写测试图，HDMI 应显示 `128x72` 放大后的彩色测试图。
3. 运行上位机，先用 `--fps 1`：确认 HDMI 画面变成摄像头图像。
4. 稳定后把 `--fps` 提到 `2`。

如果无图：

1. 确认 Vivado address editor 中 `axi_bram_ctrl_0` 地址为 `0x40000000`，范围为 `64K`。
2. 确认 PS 应用使用的 `FRAMEBUFFER_BASEADDR` 和硬件地址一致。
3. 用 SDK/Vitis 打印 `xparameters.h` 中的 BRAM base address。
4. 检查 `hdmi_pl_top` 的 BRAM Port B 是否接到 `blk_mem_gen_0/BRAM_PORTB`。

如果颜色错：

1. 检查 PC 端是否执行了 `cv2.COLOR_BGR2RGB`。
2. 检查 PS 写入是否是 `0x00RRGGBB`。
3. 检查 PL 输出是否读取 `bram_dout[23:16]`、`bram_dout[15:8]`、`bram_dout[7:0]`。

如果频繁花屏：

1. 降低 `--fps`。
2. 增加 `--line-delay`。
3. 暂时关闭 `--preview`。
4. 保持第三步单缓冲结构，允许轻微撕裂；双缓冲留到后续优化。

## 后续扩展

第 3 步完成后，再把 Sobel 接到 BRAM 输入。推荐顺序是：

1. HDMI 显示固定图片，已经完成。
2. HDMI 显示固定图片的 Sobel 结果。
3. 串口或 PS 接收一帧 `128x72` RGB 图片，先不做 Sobel，直接 HDMI 显示。
4. 接收图片写入 frame buffer。
5. Sobel 从 frame buffer 读取输入，输出到 edge buffer。
6. HDMI 从 edge buffer 读取并显示边缘图。

每一步都应保留一个能工作的 Vivado 工程，不要在同一个工程中连续叠加多个未验证功能。
