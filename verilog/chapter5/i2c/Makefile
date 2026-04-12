# Makefile for I2C write transaction simulation

IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

SRC = i2c_master.v i2c_slave.v
TB = i2c_tb.v
TOP = i2c_tb

VVP_FILE = $(TOP).vvp
VCD_FILE = $(TOP).vcd

all: compile simulate

compile: $(VVP_FILE)

$(VVP_FILE): $(SRC) $(TB)
	$(IVERILOG) -o $(VVP_FILE) $(TB) $(SRC)

simulate: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

clean:
	rm -f $(VVP_FILE) $(VCD_FILE)

.PHONY: all compile simulate wave clean