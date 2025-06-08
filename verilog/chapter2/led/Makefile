# Verilog仿真自动化脚本
SIM_NAME = sim_out
SRC_DIR = ./rtl
TB_DIR = ./tb

.PHONY: all compile simulate view clean

all: compile simulate

compile:
	iverilog -o $(SIM_NAME) \
	-y $(SRC_DIR) \
	$(TB_DIR)/led_demo_tb.v

simulate:
	vvp -n $(SIM_NAME) -lxt2

view:
	gtkwave wave.vcd &

clean:
	rm -f $(SIM_NAME) *.vcd *.lxt