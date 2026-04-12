---
description: "Use when editing src/book chapters, textbook prose, learning objectives, exercises, or chapter structure for this FPGA course. Covers Markdown-first authoring, classroom-ready Chinese style, and LaTeX-safe writing."
name: "FPGA Textbook Authoring"
applyTo: "src/book/**/*.md"
---
# Textbook Authoring Guidelines

- Treat src/book/*.md as the source of truth for the textbook. Do not hand-edit latex/generated-markdown or latex/chapters unless the task is explicitly about the conversion pipeline.
- Preserve the Markdown-first workflow. Keep frontmatter fields consistent with existing chapters unless the task requires updating chapter metadata.
- Write in formal, classroom-ready Chinese suitable for undergraduate teaching. Favor the pattern: concept background, core mechanism, design method, example, engineering meaning.
- Prefer complete explanatory paragraphs over outline-style bullet dumping. Use lists only when comparison, classification, or procedural steps are genuinely clearer.
- Keep heading hierarchy clean and avoid hard-coded section numbering inside titles or正文段落.
- When expanding a major chapter, maintain the established teaching structure where practical: learning goals, motivating example, main content, summary-style wrap-up, and chapter-end exercises or coursework items.
- Reuse verified examples from verilog/chapter*/ when they support the explanation. Do not invent HDL code that conflicts with the local chapter examples.
- Use plain Markdown, standard fenced code blocks, standard tables, and standard images. Avoid VuePress-only components, raw HTML, SVG badges, or other constructs that Pandoc and LaTeX convert poorly.
- Keep image and file references relative to src/book and compatible with the existing img*/ layout.
- If a task concerns textbook prose only, do not modify presentation/ or generated LaTeX outputs unless the user explicitly asks for synchronization.