<template><div><h1 id="第1讲-fpga架构基础" tabindex="-1"><a class="header-anchor" href="#第1讲-fpga架构基础"><span>第1讲：FPGA架构基础</span></a></h1>
<h2 id="教学目标" tabindex="-1"><a class="header-anchor" href="#教学目标"><span>教学目标</span></a></h2>
<ol>
<li>理解FPGA基本架构组成</li>
<li>掌握可编程逻辑单元结构</li>
<li>熟悉布线资源类型与特点</li>
<li>了解现代FPGA的硬核资源</li>
</ol>
<h2 id="_1-1-fpga架构组成" tabindex="-1"><a class="header-anchor" href="#_1-1-fpga架构组成"><span>1.1 FPGA架构组成</span></a></h2>
<h3 id="核心组件框图" tabindex="-1"><a class="header-anchor" href="#核心组件框图"><span>核心组件框图</span></a></h3>
<div class="language-mermaid line-numbers-mode" data-highlighter="shiki" data-ext="mermaid" data-title="mermaid" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">graph TD</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    A[可编程逻辑块CLB] --> B[布线矩阵]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    C[时钟管理单元] --> B</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    D[块存储器BRAM] --> B</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    E[数字信号处理器DSP] --> B</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    F[IOB] --> B</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="资源分布特征" tabindex="-1"><a class="header-anchor" href="#资源分布特征"><span>资源分布特征</span></a></h3>
<table>
<thead>
<tr>
<th>资源类型</th>
<th>典型密度(Xilinx UltraScale+)</th>
<th>布局特点</th>
</tr>
</thead>
<tbody>
<tr>
<td>CLB</td>
<td>1.5M LUTs</td>
<td>均匀分布</td>
</tr>
<tr>
<td>BRAM</td>
<td>4320个(36Kb)</td>
<td>列式分布</td>
</tr>
<tr>
<td>DSP Slice</td>
<td>7680个</td>
<td>模块化集群</td>
</tr>
<tr>
<td>时钟管理单元</td>
<td>32个CMT</td>
<td>四角+中心分布</td>
</tr>
</tbody>
</table>
<h2 id="_1-2-可编程逻辑单元" tabindex="-1"><a class="header-anchor" href="#_1-2-可编程逻辑单元"><span>1.2 可编程逻辑单元</span></a></h2>
<h3 id="lut结构演进" tabindex="-1"><a class="header-anchor" href="#lut结构演进"><span>LUT结构演进</span></a></h3>
<div class="language-verilog line-numbers-mode" data-highlighter="shiki" data-ext="verilog" data-title="verilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">// 4输入LUT实现示例</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">module</span><span style="--shiki-light:#C18401;--shiki-dark:#E5C07B"> LUT4</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> (</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    input</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> [</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">3</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">:</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">0</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">] addr,</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    output</span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD"> reg</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> out</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">);</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">always</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF"> @(*) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">begin</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    case</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">(addr)</span></span>
<span class="line"><span style="--shiki-light:#986801;--shiki-dark:#D19A66">        4'b0000</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: out = INIT[</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">0</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">];</span></span>
<span class="line"><span style="--shiki-light:#986801;--shiki-dark:#D19A66">        4'b0001</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: out = INIT[</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">1</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">];</span></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic">        // ... 15个case分支</span></span>
<span class="line"><span style="--shiki-light:#986801;--shiki-dark:#D19A66">        4'b1111</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: out = INIT[</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">15</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">];</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">    endcase</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">end</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD">endmodule</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="进位链结构" tabindex="-1"><a class="header-anchor" href="#进位链结构"><span>进位链结构</span></a></h3>
<p>┌───────────┐    ┌───────────┐
│  LUT/REG  │───▶│ Carry Logic│───▶
└───────────┘    └───────────┘
▲                |
└────────────────┘</p>
<h2 id="_1-3-布线资源" tabindex="-1"><a class="header-anchor" href="#_1-3-布线资源"><span>1.3 布线资源</span></a></h2>
<h3 id="布线类型对比" tabindex="-1"><a class="header-anchor" href="#布线类型对比"><span>布线类型对比</span></a></h3>
<table>
<thead>
<tr>
<th>类型</th>
<th>延迟(ps/mm)</th>
<th>适用场景</th>
<th>可编程性</th>
</tr>
</thead>
<tbody>
<tr>
<td>局部布线</td>
<td>50-100</td>
<td>CLB内部连接</td>
<td>有限</td>
</tr>
<tr>
<td>双线互联</td>
<td>120-180</td>
<td>相邻CLB连接</td>
<td>中等</td>
</tr>
<tr>
<td>长线资源</td>
<td>80-150</td>
<td>全局信号传输</td>
<td>高</td>
</tr>
<tr>
<td>时钟树</td>
<td>40-60</td>
<td>时钟分布</td>
<td>固定</td>
</tr>
</tbody>
</table>
<h2 id="_1-4-硬核模块" tabindex="-1"><a class="header-anchor" href="#_1-4-硬核模块"><span>1.4 硬核模块</span></a></h2>
<h3 id="pcie-gen4控制器参数" tabindex="-1"><a class="header-anchor" href="#pcie-gen4控制器参数"><span>PCIe Gen4控制器参数</span></a></h3>
<div class="language-json line-numbers-mode" data-highlighter="shiki" data-ext="json" data-title="json" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34"><pre v-pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">{</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75">    "lane_rate"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379">"16 Gb/s"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75">    "protocol"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379">"PCIe 4.0"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75">    "lanes"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66">8</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75">    "features"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">: [</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379">        "DMA引擎"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">,</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379">        "MSI-X中断"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">,</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379">        "SR-IOV支持"</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">,</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379">        "低延迟模式"</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">    ]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF">}</span></span></code></pre>
<div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div></div></template>


