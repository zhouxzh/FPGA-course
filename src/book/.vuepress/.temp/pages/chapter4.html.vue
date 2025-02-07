<template><div><h1 id="第4讲-高速接口协议设计" tabindex="-1"><a class="header-anchor" href="#第4讲-高速接口协议设计"><span>第4讲：高速接口协议设计</span></a></h1>
<h2 id="教学目标" tabindex="-1"><a class="header-anchor" href="#教学目标"><span>教学目标</span></a></h2>
<ol>
<li>掌握主流高速接口协议架构与实现方法</li>
<li>理解时序约束在高速接口设计中的关键作用</li>
<li>能够独立完成千兆级接口的RTL设计与验证</li>
</ol>
<hr>
<h2 id="axi4总线协议详解" tabindex="-1"><a class="header-anchor" href="#axi4总线协议详解"><span>AXI4总线协议详解</span></a></h2>
<h3 id="协议版本对比" tabindex="-1"><a class="header-anchor" href="#协议版本对比"><span>协议版本对比</span></a></h3>
<table>
<thead>
<tr>
<th>类型</th>
<th>数据位宽</th>
<th>突发传输</th>
<th>应用场景</th>
</tr>
</thead>
<tbody>
<tr>
<td>AXI4-Lite</td>
<td>32/64bit</td>
<td>不支持</td>
<td>寄存器配置接口</td>
</tr>
<tr>
<td>AXI4-Stream</td>
<td>任意</td>
<td>连续传输</td>
<td>视频流数据处理</td>
</tr>
<tr>
<td>AXI4-Full</td>
<td>512bit</td>
<td>支持</td>
<td>高性能存储访问</td>
</tr>
</tbody>
</table>
<p><strong>关键信号时序：</strong></p>
<div class="language-verilog line-numbers-mode" data-highlighter="shiki" data-ext="verilog" data-title="verilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 写地址通道示例</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">always</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> @(</span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">posedge</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> ACLK) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    if</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (AWVALID &#x26;&#x26; AWREADY) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        awaddr_reg  &#x3C;= AWADDR;</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        awburst_reg &#x3C;= AWBURST; </span><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 突发类型</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        awlen_reg   &#x3C;= AWLEN;   </span><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 突发长度</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    end</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">end</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><hr>
<h2 id="ddr3-4接口时序约束" tabindex="-1"><a class="header-anchor" href="#ddr3-4接口时序约束"><span>DDR3/4接口时序约束</span></a></h2>
<h3 id="时序参数约束示例" tabindex="-1"><a class="header-anchor" href="#时序参数约束示例"><span>时序参数约束示例</span></a></h3>
<div class="language-tcl line-numbers-mode" data-highlighter="shiki" data-ext="tcl" data-title="tcl" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">create_clock -name sys_clk -period </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">3.33</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [get_ports DDR_CLK]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">set_input_delay -clock sys_clk -max </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">1.2</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [get_ports DDR_DQ]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">set_output_delay -clock sys_clk -max </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">1.1</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [get_ports DDR_DQS]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic"># 建立/保持时间余量分析</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">set</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> setup_margin </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">0.3</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">set</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> hold_margin </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">0.25</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="校准电路设计要点" tabindex="-1"><a class="header-anchor" href="#校准电路设计要点"><span>校准电路设计要点</span></a></h3>
<ol>
<li>写均衡（Write Leveling）电路实现</li>
<li>读数据眼图训练（Read Training）</li>
<li>ZQ校准电阻自动调整</li>
</ol>
<hr>
<h2 id="千兆以太网mac层设计" tabindex="-1"><a class="header-anchor" href="#千兆以太网mac层设计"><span>千兆以太网MAC层设计</span></a></h2>
<h3 id="帧结构处理流程" tabindex="-1"><a class="header-anchor" href="#帧结构处理流程"><span>帧结构处理流程</span></a></h3>
<div class="language-systemverilog line-numbers-mode" data-highlighter="shiki" data-ext="systemverilog" data-title="systemverilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span>module eth_mac (</span></span>
<span class="line"><span>    input logic rx_clk,</span></span>
<span class="line"><span>    input logic [7:0] rxd,</span></span>
<span class="line"><span>    output logic [31:0] tx_fifo_data,</span></span>
<span class="line"><span>    // CRC校验模块</span></span>
<span class="line"><span>    output logic [31:0] crc_result</span></span>
<span class="line"><span>);</span></span>
<span class="line"><span>    // 前导码检测</span></span>
<span class="line"><span>    always_ff @(posedge rx_clk) begin</span></span>
<span class="line"><span>        if (preamble_detect(rxd)) </span></span>
<span class="line"><span>            state &#x3C;= FRAME_START;</span></span>
<span class="line"><span>    end</span></span>
<span class="line"><span>    </span></span>
<span class="line"><span>    // IP头校验和计算</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div></div></template>


