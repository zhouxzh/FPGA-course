# Project Guidelines

## Workspace Focus

- Primary authoring happens on Windows 11. Use PowerShell-oriented commands for documentation, LaTeX, presentation, and deployment tasks.
- Run Verilog simulation inside WSL. This repository's iverilog, vvp, and gtkwave workflow is available in Linux, not in native Windows.

## Architecture

- The textbook source of truth lives in src/book/*.md. Prefer editing those Markdown chapters instead of generated outputs.
- latex/convert-vuepress.ps1 converts src/book content into latex/generated-markdown and latex/chapters, renders Mermaid blocks to PNG, and then builds latex/FPGA.tex with latexmk. Treat latex/generated-markdown and latex/chapters as generated files unless the task is explicitly about the conversion pipeline.
- presentation/chapter*/ contains Beamer slide sources and per-chapter build scripts. Keep slide work scoped there unless the user explicitly asks to synchronize textbook and slide content.
- verilog/chapter*/ contains chapter-specific RTL and simulation examples, usually with a local Makefile. LED_matrix/ contains vendor project files and Python utilities for board-side experiments.

## Build And Test

- Install Node dependencies with pnpm install.
- Use pnpm docs:dev and pnpm docs:build from the repository root for the VuePress site.
- Use PowerShell for the book pipeline: .\latex\convert-vuepress.ps1 regenerates LaTeX chapters and builds latex/FPGA.tex.
- Use PowerShell for deployment: .\deploy.ps1 builds the site and force-pushes the deploy branch.
- Use WSL for HDL simulation, for example under verilog/chapter*/... run make, make clean, and make wave only when the WSL environment has the required tools.
- Presentation builds are chapter-local. Run the build.ps1 script in the relevant presentation/chapter*/ directory instead of inventing a shared top-level slide command.

## Conventions

- Preserve UTF-8 Chinese content and the Markdown-first authoring workflow.
- Avoid introducing VuePress-only components, raw HTML, SVG badges, or other Markdown constructs that Pandoc and LaTeX convert poorly. Prefer plain links, standard fenced code blocks, and standard Markdown images.
- Mermaid fenced blocks are supported because the LaTeX conversion script renders them to generated PNG assets.
- When editing textbook prose, keep a formal, classroom-ready Chinese style consistent with src/book/README.md and the existing chapter files.
- Do not spend time editing generated artifacts such as *.aux, *.fdb_latexmk, *.fls, *.toc, *.xdv, or vendor implementation output folders unless the task explicitly targets them.
- If a LaTeX build starts failing after Markdown edits, check whether the new content introduced Pandoc-incompatible constructs before changing the LaTeX templates or generated files.

## References

- See README.md for the repository overview and deployment entry point.
- See src/book/README.md for the textbook structure, writing scope, and chapter-level teaching intent.
- See .github/agents/fpga-course-editor.agent.md when the task is specifically about textbook or slide rewriting in the established teaching style.