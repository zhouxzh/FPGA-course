import{_ as s}from"./plugin-vue_export-helper-DlAUqK2U.js";import{c as a,f as n,o as e}from"./app-Eqe_4fy1.js";const t={};function l(h,i){return e(),a("div",null,i[0]||(i[0]=[n(`<h1 id="第1讲-fpga架构基础" tabindex="-1"><a class="header-anchor" href="#第1讲-fpga架构基础"><span>第1讲：FPGA架构基础</span></a></h1><h2 id="教学目标" tabindex="-1"><a class="header-anchor" href="#教学目标"><span>教学目标</span></a></h2><ol><li>理解FPGA基本架构组成</li><li>掌握可编程逻辑单元结构</li><li>熟悉布线资源类型与特点</li><li>了解现代FPGA的硬核资源</li></ol><h2 id="_1-1-fpga架构组成" tabindex="-1"><a class="header-anchor" href="#_1-1-fpga架构组成"><span>1.1 FPGA架构组成</span></a></h2><h3 id="核心组件框图" tabindex="-1"><a class="header-anchor" href="#核心组件框图"><span>核心组件框图</span></a></h3><div class="language-mermaid line-numbers-mode" data-highlighter="shiki" data-ext="mermaid" data-title="mermaid" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34;"><pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">graph TD</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">    A[可编程逻辑块CLB] --&gt; B[布线矩阵]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">    C[时钟管理单元] --&gt; B</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">    D[块存储器BRAM] --&gt; B</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">    E[数字信号处理器DSP] --&gt; B</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">    F[IOB] --&gt; B</span></span></code></pre><div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0;"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="资源分布特征" tabindex="-1"><a class="header-anchor" href="#资源分布特征"><span>资源分布特征</span></a></h3><table><thead><tr><th>资源类型</th><th>典型密度(Xilinx UltraScale+)</th><th>布局特点</th></tr></thead><tbody><tr><td>CLB</td><td>1.5M LUTs</td><td>均匀分布</td></tr><tr><td>BRAM</td><td>4320个(36Kb)</td><td>列式分布</td></tr><tr><td>DSP Slice</td><td>7680个</td><td>模块化集群</td></tr><tr><td>时钟管理单元</td><td>32个CMT</td><td>四角+中心分布</td></tr></tbody></table><h2 id="_1-2-可编程逻辑单元" tabindex="-1"><a class="header-anchor" href="#_1-2-可编程逻辑单元"><span>1.2 可编程逻辑单元</span></a></h2><h3 id="lut结构演进" tabindex="-1"><a class="header-anchor" href="#lut结构演进"><span>LUT结构演进</span></a></h3><div class="language-verilog line-numbers-mode" data-highlighter="shiki" data-ext="verilog" data-title="verilog" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34;"><pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic;">// 4输入LUT实现示例</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">module</span><span style="--shiki-light:#C18401;--shiki-dark:#E5C07B;"> LUT4</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;"> (</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">    input</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;"> [</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">3</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">:</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">0</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">] addr,</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">    output</span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;"> reg</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;"> out</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">);</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">always</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;"> @(*) </span><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">begin</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">    case</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">(addr)</span></span>
<span class="line"><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">        4&#39;b0000</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: out = INIT[</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">0</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">];</span></span>
<span class="line"><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">        4&#39;b0001</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: out = INIT[</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">1</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">];</span></span>
<span class="line"><span style="--shiki-light:#A0A1A7;--shiki-light-font-style:italic;--shiki-dark:#7F848E;--shiki-dark-font-style:italic;">        // ... 15个case分支</span></span>
<span class="line"><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">        4&#39;b1111</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: out = INIT[</span><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">15</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">];</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">    endcase</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">end</span></span>
<span class="line"><span style="--shiki-light:#A626A4;--shiki-dark:#C678DD;">endmodule</span></span></code></pre><div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0;"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="进位链结构" tabindex="-1"><a class="header-anchor" href="#进位链结构"><span>进位链结构</span></a></h3><p>┌───────────┐ ┌───────────┐<br> │ LUT/REG │───▶│ Carry Logic│───▶<br> └───────────┘ └───────────┘<br> ▲ |<br> └────────────────┘</p><h2 id="_1-3-布线资源" tabindex="-1"><a class="header-anchor" href="#_1-3-布线资源"><span>1.3 布线资源</span></a></h2><h3 id="布线类型对比" tabindex="-1"><a class="header-anchor" href="#布线类型对比"><span>布线类型对比</span></a></h3><table><thead><tr><th>类型</th><th>延迟(ps/mm)</th><th>适用场景</th><th>可编程性</th></tr></thead><tbody><tr><td>局部布线</td><td>50-100</td><td>CLB内部连接</td><td>有限</td></tr><tr><td>双线互联</td><td>120-180</td><td>相邻CLB连接</td><td>中等</td></tr><tr><td>长线资源</td><td>80-150</td><td>全局信号传输</td><td>高</td></tr><tr><td>时钟树</td><td>40-60</td><td>时钟分布</td><td>固定</td></tr></tbody></table><h2 id="_1-4-硬核模块" tabindex="-1"><a class="header-anchor" href="#_1-4-硬核模块"><span>1.4 硬核模块</span></a></h2><h3 id="pcie-gen4控制器参数" tabindex="-1"><a class="header-anchor" href="#pcie-gen4控制器参数"><span>PCIe Gen4控制器参数</span></a></h3><div class="language-json line-numbers-mode" data-highlighter="shiki" data-ext="json" data-title="json" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34;"><pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">{</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">    &quot;lane_rate&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;16 Gb/s&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">    &quot;protocol&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;PCIe 4.0&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">    &quot;lanes&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#986801;--shiki-dark:#D19A66;">8</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">    &quot;features&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: [</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">        &quot;DMA引擎&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">        &quot;MSI-X中断&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">        &quot;SR-IOV支持&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">        &quot;低延迟模式&quot;</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">    ]</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">}</span></span></code></pre><div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0;"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div>`,19)]))}const r=s(t,[["render",l],["__file","chapter1.html.vue"]]),k=JSON.parse('{"path":"/book/chapter1.html","title":"第1讲：FPGA架构基础","lang":"zh-CN","frontmatter":{"description":"第1讲：FPGA架构基础 教学目标 理解FPGA基本架构组成 掌握可编程逻辑单元结构 熟悉布线资源类型与特点 了解现代FPGA的硬核资源 1.1 FPGA架构组成 核心组件框图 资源分布特征 1.2 可编程逻辑单元 LUT结构演进 进位链结构 ┌───────────┐ ┌───────────┐ │ LUT/REG │───▶│ Carry Logi...","head":[["meta",{"property":"og:url","content":"https://vuepress-theme-hope-docs-demo.netlify.app/book/chapter1.html"}],["meta",{"property":"og:site_name","content":"主页"}],["meta",{"property":"og:title","content":"第1讲：FPGA架构基础"}],["meta",{"property":"og:description","content":"第1讲：FPGA架构基础 教学目标 理解FPGA基本架构组成 掌握可编程逻辑单元结构 熟悉布线资源类型与特点 了解现代FPGA的硬核资源 1.1 FPGA架构组成 核心组件框图 资源分布特征 1.2 可编程逻辑单元 LUT结构演进 进位链结构 ┌───────────┐ ┌───────────┐ │ LUT/REG │───▶│ Carry Logi..."}],["meta",{"property":"og:type","content":"article"}],["meta",{"property":"og:locale","content":"zh-CN"}],["meta",{"property":"og:updated_time","content":"2025-02-07T06:05:57.000Z"}],["meta",{"property":"article:modified_time","content":"2025-02-07T06:05:57.000Z"}],["script",{"type":"application/ld+json"},"{\\"@context\\":\\"https://schema.org\\",\\"@type\\":\\"Article\\",\\"headline\\":\\"第1讲：FPGA架构基础\\",\\"image\\":[\\"\\"],\\"dateModified\\":\\"2025-02-07T06:05:57.000Z\\",\\"author\\":[{\\"@type\\":\\"Person\\",\\"name\\":\\"Mr.Hope\\",\\"url\\":\\"https://mister-hope.com\\"}]}"]]},"headers":[{"level":2,"title":"教学目标","slug":"教学目标","link":"#教学目标","children":[]},{"level":2,"title":"1.1 FPGA架构组成","slug":"_1-1-fpga架构组成","link":"#_1-1-fpga架构组成","children":[{"level":3,"title":"核心组件框图","slug":"核心组件框图","link":"#核心组件框图","children":[]},{"level":3,"title":"资源分布特征","slug":"资源分布特征","link":"#资源分布特征","children":[]}]},{"level":2,"title":"1.2 可编程逻辑单元","slug":"_1-2-可编程逻辑单元","link":"#_1-2-可编程逻辑单元","children":[{"level":3,"title":"LUT结构演进","slug":"lut结构演进","link":"#lut结构演进","children":[]},{"level":3,"title":"进位链结构","slug":"进位链结构","link":"#进位链结构","children":[]}]},{"level":2,"title":"1.3 布线资源","slug":"_1-3-布线资源","link":"#_1-3-布线资源","children":[{"level":3,"title":"布线类型对比","slug":"布线类型对比","link":"#布线类型对比","children":[]}]},{"level":2,"title":"1.4 硬核模块","slug":"_1-4-硬核模块","link":"#_1-4-硬核模块","children":[{"level":3,"title":"PCIe Gen4控制器参数","slug":"pcie-gen4控制器参数","link":"#pcie-gen4控制器参数","children":[]}]}],"git":{"createdTime":1738908357000,"updatedTime":1738908357000,"contributors":[{"name":"Xianzhong Zhou","username":"Xianzhong Zhou","email":"zhouxzh@gdut.edu.cn","commits":1,"url":"https://github.com/Xianzhong Zhou"}]},"readingTime":{"minutes":1.18,"words":354},"filePathRelative":"book/chapter1.md","localizedDate":"2025年2月7日","autoDesc":true}');export{r as comp,k as data};
