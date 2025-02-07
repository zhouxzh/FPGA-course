import comp from "E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter6.html.vue"
const data = JSON.parse("{\"path\":\"/chapter6.html\",\"title\":\"第6讲：设计优化技术\",\"lang\":\"zh-CN\",\"frontmatter\":{\"gitInclude\":[],\"description\":\"第6讲：设计优化技术 1. 时序收敛方法论 1.1 建立/保持时间约束 1.2 时钟域交叉分析 同步器设计要点 1.3 关键路径识别 1.4 寄存器平衡技术 2. 面积优化技巧 2.1 资源共享（乘法器案例） 2.2 逻辑折叠技术 2.3 状态机编码优化 3. 功耗分析与优化 3.1 功耗分析流程 3.2 时钟门控技术 3.3 Vivado功耗工具 运...\",\"head\":[[\"meta\",{\"property\":\"og:url\",\"content\":\"https://github.com/yourusername/fpga-book/chapter6.html\"}],[\"meta\",{\"property\":\"og:site_name\",\"content\":\"FPGA系统设计指南\"}],[\"meta\",{\"property\":\"og:title\",\"content\":\"第6讲：设计优化技术\"}],[\"meta\",{\"property\":\"og:description\",\"content\":\"第6讲：设计优化技术 1. 时序收敛方法论 1.1 建立/保持时间约束 1.2 时钟域交叉分析 同步器设计要点 1.3 关键路径识别 1.4 寄存器平衡技术 2. 面积优化技巧 2.1 资源共享（乘法器案例） 2.2 逻辑折叠技术 2.3 状态机编码优化 3. 功耗分析与优化 3.1 功耗分析流程 3.2 时钟门控技术 3.3 Vivado功耗工具 运...\"}],[\"meta\",{\"property\":\"og:type\",\"content\":\"article\"}],[\"meta\",{\"property\":\"og:locale\",\"content\":\"zh-CN\"}],[\"script\",{\"type\":\"application/ld+json\"},\"{\\\"@context\\\":\\\"https://schema.org\\\",\\\"@type\\\":\\\"Article\\\",\\\"headline\\\":\\\"第6讲：设计优化技术\\\",\\\"image\\\":[\\\"\\\"],\\\"dateModified\\\":null,\\\"author\\\":[]}\"]]},\"headers\":[{\"level\":2,\"title\":\"1. 时序收敛方法论\",\"slug\":\"_1-时序收敛方法论\",\"link\":\"#_1-时序收敛方法论\",\"children\":[{\"level\":3,\"title\":\"1.1 建立/保持时间约束\",\"slug\":\"_1-1-建立-保持时间约束\",\"link\":\"#_1-1-建立-保持时间约束\",\"children\":[]},{\"level\":3,\"title\":\"1.2 时钟域交叉分析\",\"slug\":\"_1-2-时钟域交叉分析\",\"link\":\"#_1-2-时钟域交叉分析\",\"children\":[]},{\"level\":3,\"title\":\"1.3 关键路径识别\",\"slug\":\"_1-3-关键路径识别\",\"link\":\"#_1-3-关键路径识别\",\"children\":[]},{\"level\":3,\"title\":\"1.4 寄存器平衡技术\",\"slug\":\"_1-4-寄存器平衡技术\",\"link\":\"#_1-4-寄存器平衡技术\",\"children\":[]}]},{\"level\":2,\"title\":\"2. 面积优化技巧\",\"slug\":\"_2-面积优化技巧\",\"link\":\"#_2-面积优化技巧\",\"children\":[{\"level\":3,\"title\":\"2.1 资源共享（乘法器案例）\",\"slug\":\"_2-1-资源共享-乘法器案例\",\"link\":\"#_2-1-资源共享-乘法器案例\",\"children\":[]},{\"level\":3,\"title\":\"2.2 逻辑折叠技术\",\"slug\":\"_2-2-逻辑折叠技术\",\"link\":\"#_2-2-逻辑折叠技术\",\"children\":[]},{\"level\":3,\"title\":\"2.3 状态机编码优化\",\"slug\":\"_2-3-状态机编码优化\",\"link\":\"#_2-3-状态机编码优化\",\"children\":[]}]},{\"level\":2,\"title\":\"3. 功耗分析与优化\",\"slug\":\"_3-功耗分析与优化\",\"link\":\"#_3-功耗分析与优化\",\"children\":[{\"level\":3,\"title\":\"3.1 功耗分析流程\",\"slug\":\"_3-1-功耗分析流程\",\"link\":\"#_3-1-功耗分析流程\",\"children\":[]},{\"level\":3,\"title\":\"3.2 时钟门控技术\",\"slug\":\"_3-2-时钟门控技术\",\"link\":\"#_3-2-时钟门控技术\",\"children\":[]},{\"level\":3,\"title\":\"3.3 Vivado功耗工具\",\"slug\":\"_3-3-vivado功耗工具\",\"link\":\"#_3-3-vivado功耗工具\",\"children\":[]}]},{\"level\":2,\"title\":\"4. 设计约束规范\",\"slug\":\"_4-设计约束规范\",\"link\":\"#_4-设计约束规范\",\"children\":[{\"level\":3,\"title\":\"4.1 SDC基本结构\",\"slug\":\"_4-1-sdc基本结构\",\"link\":\"#_4-1-sdc基本结构\",\"children\":[]},{\"level\":3,\"title\":\"4.2 时序例外约束\",\"slug\":\"_4-2-时序例外约束\",\"link\":\"#_4-2-时序例外约束\",\"children\":[]},{\"level\":3,\"title\":\"4.3 物理约束\",\"slug\":\"_4-3-物理约束\",\"link\":\"#_4-3-物理约束\",\"children\":[]}]}],\"readingTime\":{\"minutes\":1.76,\"words\":528},\"filePathRelative\":\"chapter6.md\",\"autoDesc\":true}")
export { comp, data }

if (import.meta.webpackHot) {
  import.meta.webpackHot.accept()
  if (__VUE_HMR_RUNTIME__.updatePageData) {
    __VUE_HMR_RUNTIME__.updatePageData(data)
  }
}

if (import.meta.hot) {
  import.meta.hot.accept(({ data }) => {
    __VUE_HMR_RUNTIME__.updatePageData(data)
  })
}
