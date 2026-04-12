---
description: "Use when editing Verilog RTL, testbenches, Makefiles, or simulation instructions for this FPGA course. Covers chapter-local structure, WSL-based iverilog workflow, and waveform verification with gtkwave."
name: "FPGA Verilog And WSL Workflow"
applyTo: "verilog/**"
---
# Verilog And WSL Guidelines

- Assume HDL simulation runs inside WSL, not native Windows. When documenting or verifying a flow, state clearly when iverilog, vvp, gtkwave, make, make clean, and make wave must run in WSL.
- Prefer the local Makefile in each example directory when one exists. Reuse its targets before inventing ad hoc compile commands.
- Keep changes scoped to the current chapter or example directory. Do not merge unrelated chapter examples into shared infrastructure unless the user asks for that refactor.
- Preserve the repository's teaching-oriented structure: synthesizable RTL in local source files, separate testbench files, and transient simulation outputs kept out of hand-edited source.
- Do not convert Linux shell commands or Makefile recipes into PowerShell syntax inside verilog/. The Makefiles are part of the WSL workflow.
- Treat generated artifacts such as sim_out, *.vcd, *.vvp, *.lxt, and *.lxt2 as disposable outputs, not source files.
- Keep example designs readable for teaching purposes. Favor explicit state machines, simple parameterization, and straightforward signal names over overly clever optimizations.
- If a task is about HDL logic or simulation, avoid touching src/book, presentation, or vendor project folders unless the user explicitly wants documentation synchronized.