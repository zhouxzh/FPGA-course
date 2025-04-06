import{_ as n}from"./plugin-vue_export-helper-DlAUqK2U.js";import{c as t,d as l,e,a as s,r as h,o as r}from"./app-B_42U4el.js";const d={};function p(o,i){const a=h("Mermaid");return r(),t("div",null,[i[0]||(i[0]=l('<h1 id="实验4-体验-arm-裸机输出-hello-world" tabindex="-1"><a class="header-anchor" href="#实验4-体验-arm-裸机输出-hello-world"><span>实验4：体验 ARM 裸机输出 &quot;Hello World&quot;</span></a></h1><p>实验工程： ps_hello（Vivado工程） 开发模式： FPGA工程师与软件工程师协同开发</p><h2 id="开发模式转型" tabindex="-1"><a class="header-anchor" href="#开发模式转型"><span>开发模式转型</span></a></h2><h3 id="开发流程转变" tabindex="-1"><a class="header-anchor" href="#开发流程转变"><span>开发流程转变</span></a></h3><p>阶段 负责人员 工作内容 PL端开发 FPGA工程师 传统FPGA逻辑开发 PS端开发 软硬件协同 FPGA搭建硬件环境 + 软件开发应用程序</p><h3 id="协同优势" tabindex="-1"><a class="header-anchor" href="#协同优势"><span>协同优势</span></a></h3>',6)),e(a,{id:"mermaid-18",code:"eJxLL0osyFAIceFSAALHaLcAd8en25c+X9H9dEdHrIKurp2CU/TzhWue7N72srX3+d51sWCFTmAZ5+jnU+Y/65gAkX+6c/PT/g0QeWewvEv0i73rQTJwA8GSLmBJ1+inu6Y8n7ICJLOr/+mehqf9EyHyrmB5t+jnm3c/3z3/5ew2oBUvV/W8WN8YywUAKzxS/g=="}),i[1]||(i[1]=s("h2",{id:"硬件平台搭建",tabindex:"-1"},[s("a",{class:"header-anchor",href:"#硬件平台搭建"},[s("span",null,"硬件平台搭建")])],-1)),i[2]||(i[2]=s("h3",{id:"vivado工程创建流程",tabindex:"-1"},[s("a",{class:"header-anchor",href:"#vivado工程创建流程"},[s("span",null,"Vivado工程创建流程")])],-1)),i[3]||(i[3]=s("p",null,"工程初始化",-1)),i[4]||(i[4]=s("p",null,"工程名称：ps_hello 开发板选择：XC7Z020CLG400-1 Block Design创建",-1)),e(a,{id:"mermaid-31",code:"eJxLy8kvT85ILCpR8AniUgACx2jnotTEklQFp5z85GwFl9TizPS8WAVdXTsFp2jHlBSFqEi/QAXPgFiwaiewhHN0UGkeVINjaUl+bmJJZn4eRIUzWIVLtHtqXmoRyFwPFx+F8KLEgoLUolguAH/NJdo="}),i[5]||(i[5]=l(`<h3 id="zynq核配置" tabindex="-1"><a class="header-anchor" href="#zynq核配置"><span>ZYNQ核配置</span></a></h3><h4 id="关键配置项" tabindex="-1"><a class="header-anchor" href="#关键配置项"><span>关键配置项：</span></a></h4><ul><li>PS-PL接口配置（AXI总线）</li><li>外设引脚分配（UART/Ethernet/USB等）</li><li>时钟树配置</li><li>DDR参数设置</li></ul><h3 id="ps端外设配置规范" tabindex="-1"><a class="header-anchor" href="#ps端外设配置规范"><span>PS端外设配置规范</span></a></h3><p>UART配置表 参数项 配置值 注意事项 外设选择 UART1 MIO48-49 电平标准 LVCMOS 3.3V Bank1需配置1.8V 波特率 115200 需与软件设置一致 DDR配置参数</p><div class="language-json line-numbers-mode" data-highlighter="shiki" data-ext="json" data-title="json" style="--shiki-light:#383A42;--shiki-dark:#abb2bf;--shiki-light-bg:#FAFAFA;--shiki-dark-bg:#282c34;"><pre class="shiki shiki-themes one-light one-dark-pro vp-code"><code><span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">{</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">  &quot;Memory Type&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;DDR3&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">  &quot;Part Number&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;MT41J256M16 RE-125&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">  &quot;Bus Width&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;32 Bit&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">  &quot;Clock Freq&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;533.333 MHz&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">,</span></span>
<span class="line"><span style="--shiki-light:#E45649;--shiki-dark:#E06C75;">  &quot;Timing Profile&quot;</span><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">: </span><span style="--shiki-light:#50A14F;--shiki-dark:#98C379;">&quot;DDR3_1066F&quot;</span></span>
<span class="line"><span style="--shiki-light:#383A42;--shiki-dark:#ABB2BF;">}</span></span></code></pre><div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0;"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h3 id="时钟配置原则" tabindex="-1"><a class="header-anchor" href="#时钟配置原则"><span>时钟配置原则</span></a></h3><p>主时钟输入：33.333MHz（板载晶振） CPU频率：666.666MHz（默认值） PL时钟供给：保持默认关闭状态 6.3 关键配置验证点 硬件工程师检查清单 PS端Bank电压配置正确 UART引脚分配与原理图一致（MIO48-49） DDR型号选择兼容列表中的最接近型号 以太网PHY时钟配置为HSTL 1.8V 软件工程师准备事项 SDK工程建立 FSBL（First Stage Bootloader）配置 串口打印驱动验证</p><h2 id="版本控制建议" tabindex="-1"><a class="header-anchor" href="#版本控制建议"><span>版本控制建议</span></a></h2>`,9)),e(a,{id:"mermaid-76",code:"eJxLzyxxL0osyOBSAILk/NzczBKFzBQrBaUAn+er1z/d0/C0f+LTdT3POiYogZUkFSXmJWcoFBTHJ+fnpWWmY+h7On/X84UNzxeuebJ729Odm5/2b3g2Ye3T3bsg2pFVurgEvWztfb533ZM9M572TIMqyEhNzs4vLVHITczMA4vkphalpyJZCAA5gEpJ"}),i[6]||(i[6]=s("p",null,"附录：常用命令速查 功能 Vivado命令",-1)),i[7]||(i[7]=s("ul",null,[s("li",null,"生成HDL封装器 generate_target all [get_files *.bd]"),s("li",null,"验证设计完整性 validate_bd_design"),s("li",null,"生成比特流文件 launch_runs impl_1 -to_step write_bitstream")],-1))])}const c=n(d,[["render",p],["__file","chapter4.html.vue"]]),g=JSON.parse('{"path":"/experiment/chapter4.html","title":"实验4：体验 ARM 裸机输出 \\"Hello World\\"","lang":"zh-CN","frontmatter":{},"headers":[{"level":2,"title":"开发模式转型","slug":"开发模式转型","link":"#开发模式转型","children":[{"level":3,"title":"开发流程转变","slug":"开发流程转变","link":"#开发流程转变","children":[]},{"level":3,"title":"协同优势","slug":"协同优势","link":"#协同优势","children":[]}]},{"level":2,"title":"硬件平台搭建","slug":"硬件平台搭建","link":"#硬件平台搭建","children":[{"level":3,"title":"Vivado工程创建流程","slug":"vivado工程创建流程","link":"#vivado工程创建流程","children":[]},{"level":3,"title":"ZYNQ核配置","slug":"zynq核配置","link":"#zynq核配置","children":[]},{"level":3,"title":"PS端外设配置规范","slug":"ps端外设配置规范","link":"#ps端外设配置规范","children":[]},{"level":3,"title":"时钟配置原则","slug":"时钟配置原则","link":"#时钟配置原则","children":[]}]},{"level":2,"title":"版本控制建议","slug":"版本控制建议","link":"#版本控制建议","children":[]}],"git":{"createdTime":1743470207000,"updatedTime":1743470207000,"contributors":[{"name":"Xianzhong Zhou","username":"Xianzhong Zhou","email":"zhouxzh@gdut.edu.cn","commits":1,"url":"https://github.com/Xianzhong Zhou"}]},"readingTime":{"minutes":1.75,"words":526},"filePathRelative":"experiment/chapter4.md","localizedDate":"2025年4月1日"}');export{c as comp,g as data};
