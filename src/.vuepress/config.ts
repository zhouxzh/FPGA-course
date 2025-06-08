import { defineUserConfig } from "vuepress";
import { hopeTheme } from "vuepress-theme-hope";

import theme from "./theme.js";

export default defineUserConfig({
  base: "/FPGA-course/",

  lang: "zh-CN",
  title: "主页",
  description: "vuepress-theme-hope 的文档演示",

  theme: hopeTheme({
    markdown: {
      mermaid: true,
    },
  }),
  // 和 PWA 一起启用
  // shouldPrefetch: false,
});

