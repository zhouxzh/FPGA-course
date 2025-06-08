# Makefile for UART RX module simulation

# Compiler and simulator
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files (include transmitter for testbench)
SRC = rx.v tx.v
TB = uart_tb.v
TOP = uart_tb

# Output files
VVP_FILE = $(TOP).vvp
VCD_FILE = $(TOP).vcd

# Default target
all: compile simulate

# Compile the design and testbench
compile: $(VVP_FILE)

$(VVP_FILE): $(SRC) $(TB)
	$(IVERILOG) -o $(VVP_FILE) $(TB) $(SRC)

# Run the simulation
simulate: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

# View waveform (if GTKWave is available)
wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

# Clean up generated files
clean:
	rm -f $(VVP_FILE) $(VCD_FILE)

# Phony targets
.PHONY: all compile simulate wave clean
