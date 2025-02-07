# 第8讲：前沿技术专题

## 高层次综合(HLS)设计流程
1. HLS技术原理
   - C/C++到RTL的转换机制
   - 流水线优化与资源调度
2. Vivado HLS开发流程
   - 设计入口：C/C++算法描述
   - 约束指定（时钟/接口/资源）
   - 优化指令（流水线/展开/数组分割）
3. 设计实例对比
   - 矩阵乘法：HLS vs RTL实现
   - 吞吐率与资源消耗分析

## FPGA加速AI推理（INT8量化实现）
```verilog
// 量化卷积层实现示例
module quant_conv #(
  parameter BIT_WIDTH = 8
)(
  input  [BIT_WIDTH-1:0]  actv,
  input  [BIT_WIDTH-1:0]  weight,
  output [2*BIT_WIDTH:0]  accum
);
  // 符号位扩展乘法
  wire signed [2*BIT_WIDTH-1:0] product = $signed(actv) * $signed(weight);
  // 累加器带饱和运算
  assign accum = (|product[2*BIT_WIDTH-1:BIT_WIDTH+1]) ? 
                 {1'b1, {(2*BIT_WIDTH){1'b0}}} : // 饱和处理
                 {1'b0, product};
endmodule
```

## 异构计算平台（Zynq UltraScale+ MPSoC）
1. 架构组成
   - 处理系统(PS)与可编程逻辑(PL)协同
   - AXI高速互联总线
2. 开发模式对比
   - Bare-metal编程
   - Linux驱动开发
   - OpenCL异构计算
3. 设计案例
   - 视频处理流水线
   - 实时控制系统

## 开源FPGA工具链（Yosys/NextPNR）
```tcl
# Yosys综合流程示例
read_verilog -sv design.sv
synth_xilinx -family xc7
write_edif -nogndvcc design.edif

# NextPNR布局布线
nextpnr-xilinx --xdc constraints.xdc \
               --edif design.edif \
               --output design.bit
```

## 实验环节
1. HLS图像滤波实现与优化
2. INT8量化MNIST分类器部署
3. Zynq PS-PL数据交互设计
4. 开源工具链全流程实践

## 扩展阅读
- Xilinx Vitis Unified Software Platform
- ONNX FPGA部署方案
- RISC-V软核在FPGA的实现
