import { sidebar } from "vuepress-theme-hope";

export default sidebar({
  "/": [
    "",
    {
      text: "理论教程",
      icon: "book",
      prefix: "/book/",
      collapsible: true,
      children: [
        "README.md",
        "chapter1.md",
        "chapter2.md",
        "chapter3.md",
        "chapter4.md",
        "chapter5.md", 
        "chapter6.md",
        "chapter7.md",
        "chapter8.md",
        "chapter9.md"
      ]
    },
    {
      text: "实验教程",
      icon: "experiment",
      prefix: "/experiment/",
      collapsible: true,
      children: [
        "README.md",
        "exp1.md",
        "exp2.md",
        "exp3.md",
        "exp4.md",
        "exp5.md", 
        "exp6.md",
        "exp7.md",
        "exp8.md",
        "exp9.md",
        "exp10.md",
        "exp11.md",
        "exp12.md",
        "exp13.md",
        "exp14.md",
        "exp15.md"
      ]
    },
  ],
});
