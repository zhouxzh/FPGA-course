# 理塘FPGA旗舰店

ZYNQ7020 图像处理课程设计 — sobel_05 PC 控制显示与多算法/图像质量扩展

平台：ALINX ZYNQ7020 / Vivado 2017.4

## 扩展题目与创新点

功能创新：同一 bitstream 下 PC 切换 original/gray/edge/overlay/binary/Prewitt/Laplacian/sharpen/mean 共 9 种模式。上位机通过 Mode/Threshold/Overlay/Quality 参数控制。

硬件侧：RGB→gray → 3×3 窗口并行计算候选结果，display_mode MUX 选择输出。

PC 端：MODE_MAP = {"original":0..."mean":8}；PS 端 mode 范围扩展至 0~8；PL 端 case(display_mode) 多路选择。

## 基础实验验收

sobel_00: RTL 仿真 + 阈值对比

![slide5_1.png](images/slide5_1.png)

![slide5_2.png](images/slide5_2.png)

sobel_01: HDMI 固定图像 + 彩色边框

![slide6_1.jpg](images/slide6_1.jpg)

![slide6_2.jpg](images/slide6_2.jpg)

sobel_02: PL Sobel 边缘 + 绿色边缘

![slide7_1.jpg](images/slide7_1.jpg)

![slide7_2.jpg](images/slide7_2.jpg)

sobel_03: UART 传图 + 红色边框

![slide8_1.jpg](images/slide8_1.jpg)

![slide8_2.jpg](images/slide8_2.jpg)

sobel_04: UART 图像 Sobel + 绿色阈值

![slide9_1.jpg](images/slide9_1.jpg)

![slide9_2.jpg](images/slide9_2.jpg)

sobel_05 基础：original/gray/edge/overlay

![slide10_1.jpg](images/slide10_1.jpg)

![slide10_2.jpg](images/slide10_2.jpg)

![slide10_3.jpg](images/slide10_3.jpg)

![slide10_4.jpg](images/slide10_4.jpg)

## 扩展结果

### binary 二值分割
Threshold=80 vs 120：阈值越高保留亮区域越少。binary 是区域分割，不同于 edge 梯度判决。

![slide14_1.jpg](images/slide14_1.jpg)

![slide14_2.jpg](images/slide14_2.jpg)

### 多算法上板显示
Prewitt(青绿)/Laplacian(黄)/sharpen(锐化)/mean(平滑) 均通过上位机切换。

![slide15_1.jpg](images/slide15_1.jpg)

![slide15_2.jpg](images/slide15_2.jpg)

![slide15_3.jpg](images/slide15_3.jpg)

![slide15_4.jpg](images/slide15_4.jpg)

### mean vs gray
mean 削弱局部噪声，画面更柔和。

![slide16_1.jpg](images/slide16_1.jpg)

![slide16_2.jpg](images/slide16_2.jpg)

### Quality 四档 (fast/normal/detail/vivid)

![slide17_1.jpg](images/slide17_1.jpg)

![slide17_2.jpg](images/slide17_2.jpg)

![slide17_3.jpg](images/slide17_3.jpg)

![slide17_4.jpg](images/slide17_4.jpg)

### sharpen + Quality 组合

![slide18_1.jpg](images/slide18_1.jpg)

![slide18_2.jpg](images/slide18_2.jpg)

![slide18_3.jpg](images/slide18_3.jpg)

![slide18_4.jpg](images/slide18_4.jpg)

## 资源与总结

Vivado 综合通过，资源利用率与时序满足要求。

![slide19_1.png](images/slide19_1.png)

![slide19_2.png](images/slide19_2.png)

总结：打通 UART→PS/PL BRAM→HDMI 全链路，新增 binary/Prewitt/Laplacian/sharpen/mean 五算法 + Quality 四档。后续向高分辨率/AXI DMA/CNN 推理扩展。
