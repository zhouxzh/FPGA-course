<template><div><h1 id="第2讲-verilog-hdl设计进阶" tabindex="-1"><a class="header-anchor" href="#第2讲-verilog-hdl设计进阶"><span>第2讲：Verilog HDL设计进阶</span></a></h1>
<h2 id="教学目标" tabindex="-1"><a class="header-anchor" href="#教学目标"><span>教学目标</span></a></h2>
<ol>
<li>掌握层次化设计方法</li>
<li>理解有限状态机优化技巧</li>
<li>熟悉流水线设计技术</li>
<li>掌握测试平台构建方法</li>
</ol>
<h2 id="_2-1-层次化设计" tabindex="-1"><a class="header-anchor" href="#_2-1-层次化设计"><span>2.1 层次化设计</span></a></h2>
<h3 id="模块化设计规范" tabindex="-1"><a class="header-anchor" href="#模块化设计规范"><span>模块化设计规范</span></a></h3>
<div class="language-verilog line-numbers-mode" data-highlighter="shiki" data-ext="verilog" data-title="verilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">module</span><span style="--shiki-light:#C18401;--shiki-dark:#E5C07B"> top</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    input</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">  clk,</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    input</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">  rst_n,</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    output</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">7</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">:</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">0</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">] result</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">);</span></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">    // 时钟生成模块实例化</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75">    clock_gen</span><span style="--shiki-light:#E45649;--shiki-dark:#E06C75"> u_clock_gen</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">(.clk_in(clk), .rst_n(rst_n), .clk_out(sys_clk));</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    </span></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">    // 数据处理模块实例化</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75">    data_processing</span><span style="--shiki-light:#E45649;--shiki-dark:#E06C75"> u_data_processing</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">(</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        .clk(sys_clk),</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        .rst_n(rst_n),</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        .result(result)</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    );</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">endmodule</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="参数传递方法" tabindex="-1"><a class="header-anchor" href="#参数传递方法"><span>参数传递方法</span></a></h3>
<table>
<thead>
<tr>
<th>传递方式</th>
<th>语法示例</th>
<th>适用场景</th>
</tr>
</thead>
<tbody>
<tr>
<td>模块参数</td>
<td>#(.WIDTH(8))</td>
<td>静态配置</td>
</tr>
<tr>
<td>generate语句</td>
<td>generate if/for</td>
<td>条件生成</td>
</tr>
<tr>
<td>`define宏定义</td>
<td>`define MAX_SIZE 1024</td>
<td>全局常量</td>
</tr>
<tr>
<td>系统参数</td>
<td>$clog2()</td>
<td>动态计算</td>
</tr>
</tbody>
</table>
<h2 id="_2-2-状态机设计" tabindex="-1"><a class="header-anchor" href="#_2-2-状态机设计"><span>2.2 状态机设计</span></a></h2>
<h3 id="三段式状态机模板" tabindex="-1"><a class="header-anchor" href="#三段式状态机模板"><span>三段式状态机模板</span></a></h3>
<div class="language-verilog line-numbers-mode" data-highlighter="shiki" data-ext="verilog" data-title="verilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 状态定义</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">typedef enum logic [</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">1</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">:</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">0</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">] {</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    IDLE,</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    WORK,</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    DONE</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">} state_t;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 状态寄存器</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">always_ff @(</span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">posedge</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> clk) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    if</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (!rst_n) curr_state &#x3C;= IDLE;</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    else</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        curr_state &#x3C;= next_state;</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 状态转移逻辑</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">always_comb </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    next_state = curr_state;</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    case</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">(curr_state)</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        IDLE: </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">if</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (start) next_state = WORK;</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        WORK: </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">if</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (done)  next_state = DONE;</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        DONE:            next_state = IDLE;</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    endcase</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">end</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h2 id="_2-3-流水线设计" tabindex="-1"><a class="header-anchor" href="#_2-3-流水线设计"><span>2.3 流水线设计</span></a></h2>
<h3 id="四级流水线结构" tabindex="-1"><a class="header-anchor" href="#四级流水线结构"><span>四级流水线结构</span></a></h3>
<div class="language-mermaid line-numbers-mode" data-highlighter="shiki" data-ext="mermaid" data-title="mermaid" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">graph LR</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    A[取指] --> B[译码]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    B --> C[执行]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    C --> D[写回]</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="时序对比" tabindex="-1"><a class="header-anchor" href="#时序对比"><span>时序对比</span></a></h3>
<table>
<thead>
<tr>
<th>设计方式</th>
<th>最大频率(MHz)</th>
<th>吞吐量(MB/s)</th>
<th>资源消耗(LUT)</th>
</tr>
</thead>
<tbody>
<tr>
<td>组合逻辑</td>
<td>120</td>
<td>480</td>
<td>850</td>
</tr>
<tr>
<td>2级流水线</td>
<td>220</td>
<td>880</td>
<td>920</td>
</tr>
<tr>
<td>4级流水线</td>
<td>350</td>
<td>1400</td>
<td>1100</td>
</tr>
</tbody>
</table>
<h2 id="_2-4-测试平台构建" tabindex="-1"><a class="header-anchor" href="#_2-4-测试平台构建"><span>2.4 测试平台构建</span></a></h2>
<h3 id="自动验证框架" tabindex="-1"><a class="header-anchor" href="#自动验证框架"><span>自动验证框架</span></a></h3>
<div class="language-systemverilog line-numbers-mode" data-highlighter="shiki" data-ext="systemverilog" data-title="systemverilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span>module tb;</span></span>
<span class="line"><span>    logic clk, rst_n;</span></span>
<span class="line"><span>    logic [7:0] data_out;</span></span>
<span class="line"><span>    </span></span>
<span class="line"><span>    // 时钟生成</span></span>
<span class="line"><span>    initial begin</span></span>
<span class="line"><span>        clk = 0;</span></span>
<span class="line"><span>        forever #5 clk = ~clk;</span></span>
<span class="line"><span>    end</span></span>
<span class="line"><span>    </span></span>
<span class="line"><span>    // 复位生成</span></span>
<span class="line"><span>    initial begin</span></span>
<span class="line"><span>        rst_n = 0;</span></span>
<span class="line"><span>        #100 rst_n = 1;</span></span>
<span class="line"><span>    end</span></span>
<span class="line"><span>    </span></span>
<span class="line"><span>    // 实例化DUT</span></span>
<span class="line"><span>    top u_dut(.*);</span></span>
<span class="line"><span>    </span></span>
<span class="line"><span>    // 自动校验</span></span>
<span class="line"><span>    initial begin</span></span>
<span class="line"><span>        #200;</span></span>
<span class="line"><span>        if (data_out !== 8'hAA) $error("Test failed!");</span></span>
<span class="line"><span>        $finish;</span></span>
<span class="line"><span>    end</span></span>
<span class="line"><span>endmodule</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div></div></template>


