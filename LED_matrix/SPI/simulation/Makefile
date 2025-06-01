# Makefile for iverilog simulation
TARGET = sim_out
SRC = ../src/spi_slave.v spi_slave_tb.v

all: compile simulate

compile:
	iverilog -o $(TARGET) $(SRC)

simulate:
	vvp $(TARGET)

wave:
	gtkwave spi_slave.vcd &

clean:
	rm -f $(TARGET) marquee_tb.vcd

.PHONY: all compile simulate wave clean
