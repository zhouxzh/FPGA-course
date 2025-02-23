import { navbar } from "vuepress-theme-hope";

export default navbar([
  "/",
  "portfolio.md",
  {
    text: "理论教程",
    link: "/book/",
    icon: "book",
    activeMatch: "^/book/"
  },
]);
