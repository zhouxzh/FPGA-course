# 第4讲：高速接口协议设计

## 教学目标
1. 掌握主流高速接口协议架构与实现方法
2. 理解时序约束在高速接口设计中的关键作用
3. 能够独立完成千兆级接口的RTL设计与验证

---

## AXI4总线协议详解
### 协议版本对比
| 类型       | 数据位宽 | 突发传输 | 应用场景          |
|------------|----------|----------|-------------------|
| AXI4-Lite  | 32/64bit | 不支持   | 寄存器配置接口    |
| AXI4-Stream| 任意     | 连续传输 | 视频流数据处理    |
| AXI4-Full  | 512bit   | 支持     | 高性能存储访问    |

**关键信号时序：**
```verilog
// 写地址通道示例
always @(posedge ACLK) begin
    if (AWVALID && AWREADY) begin
        awaddr_reg  <= AWADDR;
        awburst_reg <= AWBURST; // 突发类型
        awlen_reg   <= AWLEN;   // 突发长度
    end
end
```

---

## DDR3/4接口时序约束
### 时序参数约束示例
```tcl
create_clock -name sys_clk -period 3.33 [get_ports DDR_CLK]
set_input_delay -clock sys_clk -max 1.2 [get_ports DDR_DQ]
set_output_delay -clock sys_clk -max 1.1 [get_ports DDR_DQS]

# 建立/保持时间余量分析
set setup_margin 0.3
set hold_margin 0.25
```

### 校准电路设计要点
1. 写均衡（Write Leveling）电路实现
2. 读数据眼图训练（Read Training）
3. ZQ校准电阻自动调整

---

## 千兆以太网MAC层设计
### 帧结构处理流程
```systemverilog
module eth_mac (
    input logic rx_clk,
    input logic [7:0] rxd,
    output logic [31:0] tx_fifo_data,
    // CRC校验模块
    output logic [31:0] crc_result
);
    // 前导码检测
    always_ff @(posedge rx_clk) begin
        if (preamble_detect(rxd)) 
            state <= FRAME_START;
    end
    
    // IP头校验和计算
