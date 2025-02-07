<template><div><h1 id="第3讲-数字系统设计方法学" tabindex="-1"><a class="header-anchor" href="#第3讲-数字系统设计方法学"><span>第3讲：数字系统设计方法学</span></a></h1>
<h2 id="教学目标" tabindex="-1"><a class="header-anchor" href="#教学目标"><span>教学目标</span></a></h2>
<ol>
<li>掌握同步设计准则</li>
<li>理解时序路径分析方法</li>
<li>熟悉跨时钟域同步技术</li>
<li>了解低功耗设计策略</li>
</ol>
<h2 id="_3-1-同步设计黄金准则" tabindex="-1"><a class="header-anchor" href="#_3-1-同步设计黄金准则"><span>3.1 同步设计黄金准则</span></a></h2>
<h3 id="基本设计原则" tabindex="-1"><a class="header-anchor" href="#基本设计原则"><span>基本设计原则</span></a></h3>
<ol>
<li>单时钟域内使用同一时钟边沿</li>
<li>所有寄存器必须由复位信号初始化</li>
<li>避免使用组合逻辑反馈环路</li>
<li>时钟使能信号必须同步处理</li>
</ol>
<h3 id="时钟质量要求" tabindex="-1"><a class="header-anchor" href="#时钟质量要求"><span>时钟质量要求</span></a></h3>
<table>
<thead>
<tr>
<th>参数</th>
<th>推荐值</th>
<th>测量方法</th>
</tr>
</thead>
<tbody>
<tr>
<td>时钟抖动</td>
<td>&lt; 50ps</td>
<td>周期到周期测量</td>
</tr>
<tr>
<td>占空比失真</td>
<td>&lt; 5%</td>
<td>高电平持续时间测量</td>
</tr>
<tr>
<td>时钟偏斜</td>
<td>&lt; 100ps</td>
<td>时钟树末端差异测量</td>
</tr>
</tbody>
</table>
<h2 id="_3-2-时序路径分析" tabindex="-1"><a class="header-anchor" href="#_3-2-时序路径分析"><span>3.2 时序路径分析</span></a></h2>
<h3 id="建立-保持时间公式" tabindex="-1"><a class="header-anchor" href="#建立-保持时间公式"><span>建立/保持时间公式</span></a></h3>
<div class="language- line-numbers-mode" data-highlighter="shiki" data-ext="" data-title="" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span>建立时间裕量 = T周期 - (Tclk2q + Tcomb + Tsetup)</span></span>
<span class="line"><span>保持时间裕量 = Tclk2q + Tcomb - Thold</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="时序约束示例" tabindex="-1"><a class="header-anchor" href="#时序约束示例"><span>时序约束示例</span></a></h3>
<div class="language-tcl line-numbers-mode" data-highlighter="shiki" data-ext="tcl" data-title="tcl" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">create_clock -name sys_clk -period </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">10</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [get_ports clk]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">set_input_delay -clock sys_clk </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">2</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [all_inputs]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">set_output_delay -clock sys_clk </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">3</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [all_outputs]</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h2 id="_3-3-跨时钟域同步" tabindex="-1"><a class="header-anchor" href="#_3-3-跨时钟域同步"><span>3.3 跨时钟域同步</span></a></h2>
<h3 id="同步技术对比" tabindex="-1"><a class="header-anchor" href="#同步技术对比"><span>同步技术对比</span></a></h3>
<table>
<thead>
<tr>
<th>方法</th>
<th>延迟周期</th>
<th>适用场景</th>
<th>可靠性</th>
</tr>
</thead>
<tbody>
<tr>
<td>双锁存器</td>
<td>2</td>
<td>单bit信号</td>
<td>高</td>
</tr>
<tr>
<td>握手协议</td>
<td>4+</td>
<td>控制信号</td>
<td>极高</td>
</tr>
<tr>
<td>异步FIFO</td>
<td>N+2</td>
<td>数据总线</td>
<td>最高</td>
</tr>
<tr>
<td>脉冲展宽</td>
<td>3</td>
<td>低频脉冲信号</td>
<td>中等</td>
</tr>
</tbody>
</table>
<h3 id="异步fifo结构" tabindex="-1"><a class="header-anchor" href="#异步fifo结构"><span>异步FIFO结构</span></a></h3>
<p>┌───────────┐     ┌───────────┐
│ 写时钟域  │     │ 读时钟域  │
│ 写指针    │◀─格雷码─│ 读指针    │
│ 存储器    │     │ 空满判断  │
└───────────┘     └───────────┘</p>
<h2 id="_3-4-低功耗设计" tabindex="-1"><a class="header-anchor" href="#_3-4-低功耗设计"><span>3.4 低功耗设计</span></a></h2>
<h3 id="功耗构成分析" tabindex="-1"><a class="header-anchor" href="#功耗构成分析"><span>功耗构成分析</span></a></h3>
<div class="language-mermaid line-numbers-mode" data-highlighter="shiki" data-ext="mermaid" data-title="mermaid" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">pie</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    title 功耗分布</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    "静态功耗" : 35</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    "时钟网络" : 40</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    "逻辑翻转" : 20</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    "I/O功耗" : 5</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="时钟门控实现" tabindex="-1"><a class="header-anchor" href="#时钟门控实现"><span>时钟门控实现</span></a></h3>
<div class="language-verilog line-numbers-mode" data-highlighter="shiki" data-ext="verilog" data-title="verilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">always</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> @(</span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">posedge</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> clk) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    if</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (enable) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">        gated_clk &#x3C;= ~gated_clk;</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    end</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">assign</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> clk_gated = gated_clk &#x26; clk;</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div></div></template>


