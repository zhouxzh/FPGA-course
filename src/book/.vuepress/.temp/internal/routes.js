export const redirects = JSON.parse("{}")

export const routes = Object.fromEntries([
  ["/chapter1.html", { loader: () => import(/* webpackChunkName: "chapter1.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter1.html.js"), meta: {"t":"第1讲：FPGA架构基础"} }],
  ["/chapter2.html", { loader: () => import(/* webpackChunkName: "chapter2.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter2.html.js"), meta: {"t":"第2讲：Verilog HDL设计进阶"} }],
  ["/chapter3.html", { loader: () => import(/* webpackChunkName: "chapter3.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter3.html.js"), meta: {"t":"第3讲：数字系统设计方法学"} }],
  ["/chapter4.html", { loader: () => import(/* webpackChunkName: "chapter4.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter4.html.js"), meta: {"t":"第4讲：高速接口协议设计"} }],
  ["/chapter5.html", { loader: () => import(/* webpackChunkName: "chapter5.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter5.html.js"), meta: {"t":"第5讲：系统级设计技术"} }],
  ["/chapter6.html", { loader: () => import(/* webpackChunkName: "chapter6.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter6.html.js"), meta: {"t":"第6讲：设计优化技术"} }],
  ["/chapter7.html", { loader: () => import(/* webpackChunkName: "chapter7.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter7.html.js"), meta: {"t":"第7讲：FPGA调试与测试技术深度解析"} }],
  ["/chapter8.html", { loader: () => import(/* webpackChunkName: "chapter8.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/chapter8.html.js"), meta: {"t":"第8讲：前沿技术专题"} }],
  ["/404.html", { loader: () => import(/* webpackChunkName: "404.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/404.html.js"), meta: {"t":""} }],
  ["/", { loader: () => import(/* webpackChunkName: "index.html" */"E:/Github/FPGA/src/book/.vuepress/.temp/pages/index.html.js"), meta: {"t":""} }],
]);

if (import.meta.webpackHot) {
  import.meta.webpackHot.accept()
  if (__VUE_HMR_RUNTIME__.updateRoutes) {
    __VUE_HMR_RUNTIME__.updateRoutes(routes)
  }
  if (__VUE_HMR_RUNTIME__.updateRedirects) {
    __VUE_HMR_RUNTIME__.updateRedirects(redirects)
  }
}

if (import.meta.hot) {
  import.meta.hot.accept(({ routes, redirects }) => {
    __VUE_HMR_RUNTIME__.updateRoutes(routes)
    __VUE_HMR_RUNTIME__.updateRedirects(redirects)
  })
}
