import { navbar } from "vuepress-theme-hope";

export default navbar([
  "/",
  {
    text: "书籍文档",
    link: "/book/",
    icon: "book",
    activeMatch: "^/book/"
  },
]);
