# Verilog仿真自动化脚本

.PHONY: all compile simulate view clean

all: compile simulate

compile:
	verilator --cc --exe --build -Wall --trace tb.v top.v main.cpp

simulate:
	./obj_dir/Vtb

view:
	gtkwave wave.vcd &

clean:
	rm -rf $(SIM_NAME) *.vcd obj_dir