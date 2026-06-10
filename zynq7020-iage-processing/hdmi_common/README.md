# hdmi_common

本目录是 Sobel 系列 Vivado 工程共用的 HDMI 基础依赖目录，不能删除。

以下工程的 `.xpr` 文件中保留了指向 `../hdmi_common` 的相对路径：

```text
sobel_01_hdmi_pattern
sobel_02_hdmi_sobel
sobel_03_uart_hdmi
sobel_04_uart_sobel_hdmi
```

该目录用于保存 HDMI 相关工程依赖路径和 Vivado 缓存来源，例如 `video_clock`、`rgb2dvi_0`、`hdmi_out_test.xdc`、IP repository 路径以及仿真库缓存目录。删除该目录后，Vivado 重新打开工程或重新生成 IP 时可能出现路径缺失，或者重新创建旧的临时目录。
