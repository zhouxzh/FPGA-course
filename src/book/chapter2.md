# 第2讲：Verilog HDL设计进阶

## 2.1 层次化设计
### 模块化设计规范
```verilog
module top (
    input  clk,
    input  rst_n,
    output [7:0] result
);
    // 时钟生成模块实例化
    clock_gen u_clock_gen(.clk_in(clk), .rst_n(rst_n), .clk_out(sys_clk));
    
    // 数据处理模块实例化
    data_processing u_data_processing(
        .clk(sys_clk),
        .rst_n(rst_n),
        .result(result)
    );
endmodule
```

### 参数传递方法
| 传递方式      | 语法示例                  | 适用场景          |
|---------------|--------------------------|-------------------|
| 模块参数       | #(.WIDTH(8))             | 静态配置          |
| generate语句   | generate if/for          | 条件生成          |
| `define宏定义  | `define MAX_SIZE 1024    | 全局常量          |
| 系统参数       | $clog2()                 | 动态计算          |

## 2.2 状态机设计
### 三段式状态机模板
```verilog
// 状态定义
typedef enum logic [1:0] {
    IDLE,
    WORK,
    DONE
} state_t;

// 状态寄存器
always_ff @(posedge clk) begin
    if (!rst_n) curr_state <= IDLE;
    else        curr_state <= next_state;
end

// 状态转移逻辑
always_comb begin
    next_state = curr_state;
    case(curr_state)
        IDLE: if (start) next_state = WORK;
        WORK: if (done)  next_state = DONE;
        DONE:            next_state = IDLE;
    endcase
end
```

## 2.3 流水线设计
### 四级流水线结构
```mermaid
graph LR
    A[取指] --> B[译码]
    B --> C[执行]
    C --> D[写回]
```

### 时序对比
| 设计方式      | 最大频率(MHz) | 吞吐量(MB/s) | 资源消耗(LUT) |
|--------------|---------------|--------------|---------------|
| 组合逻辑      | 120           | 480          | 850           |
| 2级流水线     | 220           | 880          | 920           |
| 4级流水线     | 350           | 1400         | 1100          |

## 2.4 测试平台构建
### 自动验证框架
```systemverilog
module tb;
    logic clk, rst_n;
    logic [7:0] data_out;
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 复位生成
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end
    
    // 实例化DUT
    top u_dut(.*);
    
    // 自动校验
    initial begin
        #200;
        if (data_out !== 8'hAA) $error("Test failed!");
        $finish;
    end
endmodule
