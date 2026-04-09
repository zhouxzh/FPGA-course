# FPGA系统设计

我们周围的世界已经变得数字化。我们使用的个人设备、居住的房屋和驾驶的汽车都包含数字系统来简化生活。此外，所有这些系统已经开始相互通信。由于数字系统已成为我们日常生活中最重要的工具之一，除了工程师之外，业余爱好者也开始学习和使用它们。

实现数字系统有四种方法。第一种是使用分立逻辑门。由于实现问题，这种方法已经过时。第二种是使用微控制器，它具有编程简便和价格合理等理想特性。然而，微控制器在配置方面是静态的。第三种是使用专用集成电路（ASIC）。对于大规模生产，使用ASIC是解决方案。然而，生产和测试ASIC芯片需要时间，这限制了其设计后的修改。第四种是使用现场可编程门阵列（FPGA）。FPGA可以轻松配置以适应特定应用。

管理FPGA并充分发挥其性能比微控制器稍难。但如果操作得当，收益将是巨大的。因此，本书旨在通过数字系统设计指导读者掌握FPGA。在此过程中，主要关注点将放在实现上。因此，读者将通过实现实际应用来掌握理论数字设计概念。

有两种常用的硬件描述语言（HDL）可用于在FPGA上实现数字系统：Verilog和VHDL。每种HDL都有其优缺点。在本书中，我们只介绍Verilog。

在深入数字系统的精彩世界之前，我们想提醒读者一两件事。我们并没有打算编写标准的数字设计课程教科书，因此没有深入涵盖理论概念。相反，我们尝试通过实际应用来解释所有这些概念。通过这种方式，我们希望读者能更好地理解数字设计概念。此外，我们不相信数字设计只是一门必须参加的工程课程，它是每个工程专业学生为就业市场应该掌握的技能。同时，正如大多数业余爱好者所做的那样，它也是充满趣味的。所以，让我们在掌握FPGA的同时享受数字设计的乐趣吧！

## 参考文献与延伸阅读

为避免在各章末尾重复列出参考文献，现将 chapter1-9 对应的延伸阅读与参考资料统一汇总在本 README 中，便于课程教学、备课和后续查阅。

- 第1讲：FPGA 系统设计概述。建议查阅 FPGA 厂商器件手册、开发工具用户指南与典型应用白皮书，并结合数字集成电路设计流程入门材料、ASIC 前后端设计方法和 SoC 架构设计资料，建立对 FPGA 在数字系统设计链条中定位的整体认识。

- 第2讲：FPGA与CPLD架构基础。建议重点阅读典型 FPGA 与 CPLD 器件的数据手册和用户指南，关注逻辑资源、存储资源、时钟资源与配置方式，同时结合 LUT 映射、时序驱动布局布线和片上互连优化等延伸资料理解其架构特点。

- 第3讲：开源 Verilog 仿真工具。建议结合 Icarus Verilog 使用文档、GTKWave 波形分析资料与 Verilator 官方示例开展学习，并可进一步扩展到 Cocotb、SystemC、覆盖率分析和自动化回归测试等验证方法。

- 第4讲：开源 Verilog 综合工具。建议阅读 Yosys 官方手册与交互式综合示例，重点关注 RTLIL、中间表示转换、状态机提取和技术映射等内容，同时了解 Yosys 与 nextpnr 配合使用的开源 FPGA 实现流程。

- 第5讲：FPGA数字接口设计。建议结合 UART、SPI、I²C 协议基础文档与实验案例学习接口设计，并进一步查阅具体器件数据手册中关于 SPI 模式配置、I²C 时序参数、LVDS 约束设置和 HDMI 视频时序的说明，强化板级实现与调试能力。

- 第6讲：系统级设计技术。建议阅读基于 IP 核的系统集成设计资料，并结合软核处理器外设访问、寄存器映射和系统联调案例，进一步了解片上总线协议、DMA、缓存一致性和软硬件协同设计等系统级方法。

- 第7讲：设计优化技术。建议查阅 FPGA 厂商关于时序约束、功耗分析和 CDC 设计规范的官方文档，并结合时序收敛、面积优化、功耗优化、流水线重构和关键路径分析等工程案例开展深入学习。

- 第8讲：FPGA 调试、测试与 SystemC 建模。建议阅读 FPGA 厂商在线调试工具文档，如 ILA、VIO 等，同时结合 SystemC 官方示例、模块与进程入门资料，以及 Verilator 与 SystemC 联合验证、仿真控制、波形跟踪和测试平台组织相关内容进行扩展。

- 第9讲：前沿技术专题。建议根据兴趣选择 HLS 与量化推理、PS-PL 协同与异构 SoC 平台开发，或开源 FPGA 工具链中的综合、布局布线与自动化流程等方向进行进一步阅读和跟进。

## 参考文献

教材与基础资料：

1. Brown S, Vranesic Z. Fundamentals of Digital Logic with Verilog Design[M]. New York: McGraw-Hill.
2. Palnitkar S. Verilog HDL: A Guide to Digital Design and Synthesis[M]. Upper Saddle River: Pearson.
3. Chu P P. FPGA Prototyping by Verilog Examples[M]. Hoboken: Wiley.
4. Wolf W. FPGA-Based System Design[M]. Upper Saddle River: Prentice Hall.
5. Ciletti M D. Advanced Digital Design with the Verilog HDL[M]. Upper Saddle River: Pearson.

厂商工具与器件文档：

1. AMD Xilinx. Vivado Design Suite User Guide[Z]. 重点参考综合、约束、实现与调试相关文档。
2. Intel. Quartus Prime User Guide[Z]. 重点参考设计输入、分析综合、时序约束与片上调试相关文档。
3. Lattice Semiconductor. FPGA Design Documentation and Family Data Sheet[Z].
4. AMD. Zynq SoC Platform User Guide[Z].
5. Intel. SoC FPGA Documentation[Z].
6. HDMI、LVDS、UART、SPI、I²C 等接口器件数据手册与应用笔记[Z]. 建议结合具体开发板和芯片型号查阅。

开源工具链与验证资料：

1. Wolf C, et al. Yosys Open SYnthesis Suite Documentation[Z].
2. nextpnr Documentation and Project Materials[Z].
3. Icarus Verilog Documentation[Z].
4. GTKWave User's Guide[Z].
5. Verilator User Guide[Z].
6. Accellera Systems Initiative. SystemC 2.3.x Language Reference Manual[Z].

协议与系统设计资料：

1. Arm. AMBA AXI and ACE Protocol Specification[Z].
2. 软核处理器、片上总线、DMA、缓存一致性及软硬件协同设计相关技术手册与应用资料[Z].

前沿专题拓展资料：

1. AMD Xilinx. Vitis HLS User Guide[Z].
2. Intel. HLS Compiler Documentation[Z].
3. HLS、量化推理、异构 SoC 平台与开源 FPGA 自动化流程相关论文、白皮书与官方示例资料[Z].

## 使用建议

- 初学阶段优先阅读器件手册、工具指南和实验文档，先建立“器件-工具-流程”的整体认识。
- 进入课程中后期后，再逐步扩展到时序优化、系统集成、板级调试与高层建模资料。
- 对于前沿专题，建议遵循“选择一个方向深入，其余方向建立概念框架”的学习方式，以提高本科阶段的学习效率。

