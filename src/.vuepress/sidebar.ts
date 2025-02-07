import { sidebar } from "vuepress-theme-hope";

export default sidebar({
  "/": [
    "",
    {
      text: "书籍章节",
      icon: "book",
      prefix: "/book/",
      collapsible: true,
      children: [
        "chapter1.md",
        "chapter2.md",
        "chapter3.md",
        "chapter4.md",
        "chapter5.md", 
        "chapter6.md",
        "chapter7.md",
        "chapter8.md"
      ]
    },
    {
      text: "幻灯片",
      icon: "person-chalkboard",
      link: "https://ecosystem.vuejs.press/zh/plugins/markdown/revealjs/demo.html",
    },
  ],
});
