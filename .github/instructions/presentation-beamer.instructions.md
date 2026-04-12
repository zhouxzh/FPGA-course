---
description: "Use when editing presentation slides, Beamer sources, chapter-local slide assets, or teaching decks under presentation/. Covers chapter-local slide structure, Pandoc and Beamer compatibility, and classroom projection readability."
name: "FPGA Presentation And Beamer"
applyTo: "presentation/**"
---
# Presentation And Beamer Guidelines

- Follow the local structure of the target chapter. Some chapters are a single chapter*.tex file, while others are split into section*.tex files and local asset folders. Preserve the chapter's existing organization.
- Treat slides as presentation material, not pasted textbook prose. Convert long explanations into frame-sized teaching points, comparisons, diagrams, and short code excerpts.
- Optimize for classroom projection: one main idea per frame, short paragraphs, limited bullets, and visuals or code only when they directly support the teaching point.
- Keep Chinese text and fonts compatible with the current Beamer workflow. Avoid Markdown or LaTeX constructs that are likely to break the chapter-local Pandoc and xelatex pipeline.
- Run the build script inside the relevant presentation/chapter*/ directory when validation is needed. Do not invent a shared top-level slide build command.
- Do not rewrite the textbook in src/book just because slides need to change. Synchronize textbook and presentation content only when the user explicitly asks for both.
- Preserve the existing chapter title, section pacing, and lecture-oriented framing unless the task specifically requests a structural rewrite.
- Avoid editing generated build outputs such as *.aux, *.nav, *.snm, *.toc, *.xdv, *.vrb, or compiled PDFs unless the task explicitly targets them.