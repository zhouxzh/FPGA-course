import { defineUserConfig } from "vuepress";
import { hopeTheme } from "vuepress-theme-hope";

export default defineUserConfig({
  base: "/",
  lang: "zh-CN",
  title: "FPGA系统设计指南",
  description: "开源FPGA系统设计电子书",

  theme: hopeTheme({
    hostname: "https://github.com/yourusername/fpga-book",
    
    // 导航栏配置
    navbar: [
      { text: "首页", link: "/" },
      { text: "书籍目录", link: "/book/", activeMatch: "^/book/" },
      {
        text: "GitHub",
        icon: "github",
        link: "https://github.com/yourusername/fpga-book",
      },
    ],

    // 侧边栏配置
    sidebar: {
      "/book/": [
        {
          text: "FPGA系统设计",
          collapsible: true,
          children: [
            "/book/chapter1.md",
            "/book/chapter2.md",
            "/book/chapter3.md",
            "/book/chapter4.md",
            "/book/chapter5.md",
            "/book/chapter6.md",
            "/book/chapter7.md",
            "/book/chapter8.md",
          ],
        },
      ],
    },

    // 插件增强配置
    markdown: {
      codeTabs: true,
      math: true,
      footnote: true,
      mark: true,
      tasklist: true,
    },

    // 电子书专用配置
    book: {
      sidebar: "structure",
      pageInfo: ["Author", "Original", "Date", "Category", "Tag", "ReadingTime"],
      prev: true,
      next: true,
      // 添加PDF导出功能
      pdf: {
        print: true,
        open: true,
      },
      // 全屏阅读模式
      fullscreen: true,
      // 版权信息
      copyright: "本作品采用<a href=\"https://creativecommons.org/licenses/by-nc-sa/4.0/\" target=\"_blank\">CC BY-NC-SA 4.0</a>协议授权",
      // 社交媒体分享
      socialShare: true,
      socialSharePopover: [
        ["QQ", "https://web.guangdian.live/v3/explore/0"],
        ["Wechat", "https://web.guangdian.live/v3/explore/0"],
        ["Email", "mailto:your-email@example.com"]
      ]
    },
    
    // 主题外观配置
    iconAssets: "iconfont",
    darkmode: "switch",
    themeColor: {
      blue: "#2196f3",
      red: "#f26d6d",
      green: "#3eaf7c",
      orange: "#fb9b5f"
    }
  }),
  
  // 分页导航插件
  plugins: [
    [
      "@vuepress/plugin-docsearch",
      {
        locales: {
          "/": {
            placeholder: "搜索文档",
          },
        },
      },
    ],
  ],
});
