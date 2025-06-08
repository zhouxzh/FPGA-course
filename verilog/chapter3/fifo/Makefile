# Verilog仿真工具配置
COMPILER = iverilog
SIMULATOR = vvp
VIEWER = gtkwave

# 源文件配置
SOURCE = fifo.v fifo_tb.v
TB_TOP = fifo_tb
WAVE_FILE = fifo.vcd
SIM_BIN = sim

# 编译选项
FLAGS = -Wall -g2012

all: sim wave

compile:
	$(COMPILER) $(FLAGS) -o $(SIM_BIN) $(SOURCE)

sim: compile
	$(SIMULATOR) $(SIM_BIN) -l $(TB_TOP).log

wave:
	$(VIEWER) $(WAVE_FILE) &

clean:
	rm -f $(SIM_BIN) $(WAVE_FILE) $(TB_TOP).log

.PHONY: all compile sim wave clean