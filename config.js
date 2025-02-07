import { defineUserConfig } from "vuepress";
import { hopeTheme } from "vuepress-theme-hope";

export default defineUserConfig({
  base: "/",
  // 设置文档目录
  dest: "./dist",
  srcDir: "./src",
  lang: "zh-CN",
  title: "FPGA系统设计指南",
  description: "开源FPGA系统设计电子书",

  theme: hopeTheme({
    // 主题基本配置
    hostname: "https://github.com/zhouxzh/fpga-course",
    iconAssets: "iconfont",
    
    // 导航栏配置
    navbar: [
      { 
        text: "首页", 
        link: "/", 
        icon: "home" 
      },
      { 
        text: "书籍目录",
        link: "/book/",
        icon: "list",
        activeMatch: "^/book/"
      },
      {
        text: "GitHub",
        icon: "github",
        link: "https://github.com/zhouxzh/fpga-course"
      }
    ],

    // 侧边栏配置
    sidebar: {
      "/book/": [
        {
          text: "章节列表",
          icon: "read",
          prefix: "book/",
          collapsible: false,
          children: [
            { text: "第一章", link: "chapter1" },
            { text: "第二章", link: "chapter2" },
            { text: "第三章", link: "chapter3" },
            { text: "第四章", link: "chapter4" },
            { text: "第五章", link: "chapter5" },
            { text: "第六章", link: "chapter6" },
            { text: "第七章", link: "chapter7" },
            { text: "第八章", link: "chapter8" }
          ]
        }
      ]
    },
    
    // 主题插件配置
    plugins: {
      mdEnhance: {
        presentation: true,
        sub: true,
        sup: true
      }
    }
  })
})
