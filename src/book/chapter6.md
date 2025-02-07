# 第6讲：设计优化技术

## 1. 时序收敛方法论
### 1.1 建立/保持时间约束
```tcl
create_clock -period 10 [get_ports clk]
set_input_delay -clock clk 2 [get_ports data_in]
set_output_delay -clock clk 1 [get_ports data_out]
```

### 1.2 时钟域交叉分析
- 同步器设计要点
```verilog
always @(posedge clk_dst) begin
    meta_reg <= data_src;
    stable_reg <= meta_reg;
end
```

### 1.3 关键路径识别
```tcl
report_timing -slack_lesser_than 0 -nworst 10 -setup
```

### 1.4 寄存器平衡技术
```verilog
// 优化前
always @(posedge clk) 
    out <= a + b + c + d;

// 优化后（插入流水线寄存器）
reg [31:0] stage1;
always @(posedge clk) begin
    stage1 <= a + b;
    out <= stage1 + c + d;
end
```

## 2. 面积优化技巧
### 2.1 资源共享（乘法器案例）
```verilog
// 时分复用乘法器
module shared_mult(
    input clk,
    input [3:0] sel,
    input [15:0] a, b,
    output reg [31:0] y
);
    reg [31:0] temp;
    always @(posedge clk) begin
        case(sel)
            4'b0001: temp <= a[7:0] * b[7:0];
            4'b0010: temp <= a[15:8] * b[15:8];
            // ...其他通道
        endcase
        y <= temp;
    end
endmodule
```

### 2.2 逻辑折叠技术
```verilog
// 优化前组合逻辑
assign result = (a & b) | (c ^ d);

// 优化后时序逻辑
always @(posedge clk)
    result <= (a & b) | (c ^ d);
```

### 2.3 状态机编码优化
| 状态     | Binary | Gray   | One-Hot |
|----------|--------|--------|---------|
| IDLE     | 000    | 000    | 0000001 |
| START    | 001    | 001    | 0000010 |
| ...      | ...    | ...    | ...     |

## 3. 功耗分析与优化
### 3.1 功耗分析流程
```tcl
read_verilog top.v
link_design
report_power
```

### 3.2 时钟门控技术
```verilog
// 传统设计
always @(posedge clk)
    if(en) q <= d;

// 时钟门控实现
wire gated_clk = clk & en;
always @(posedge gated_clk)
    q <= d;
```

### 3.3 Vivado功耗工具
1. 运行设计实现
2. 打开Implemented Design
3. Report Power
4. 分析静态/动态功耗分布

## 4. 设计约束规范
### 4.1 SDC基本结构
```tcl
# 时钟定义
create_clock -name sys_clk -period 10 [get_ports clk]

# 输入输出约束
set_input_delay -clock sys_clk 2 [all_inputs]
set_output_delay -clock sys_clk 1 [all_outputs]

# 跨时钟域约束
set_clock_groups -asynchronous -group {clk1} -group {clk2}

# 多周期路径
set_multicycle_path 3 -setup -from [get_clocks clkA] -to [get_clocks clkB]
```

### 4.2 时序例外约束
| 约束类型          | 应用场景                  | 示例                          |
|-------------------|---------------------------|-------------------------------|
| set_false_path    | 异步时钟域间路径          | set_false_path -from clkA -to clkB |
| set_multicycle_path | 慢速数据通路            | set_multicycle_path 2 -hold -from regA |
| set_max_delay     | 特定路径约束              | set_max_delay 5 -from [get_pins inst1/O] |

### 4.3 物理约束
```tcl
# I/O管脚约束
set_property PACKAGE_PIN AJ12 [get_ports {data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {data[0]}]

# 布局约束
place_cell inst_A RAMB36_X0Y5
