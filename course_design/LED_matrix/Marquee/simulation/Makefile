# Makefile for iverilog simulation
TARGET = sim_out
SRC = ../src/Marquee.v Marquee_tb.v

all: compile simulate

compile:
	iverilog -o $(TARGET) $(SRC)

simulate:
	vvp $(TARGET)

wave:
	gtkwave marquee_tb.vcd &

clean:
	rm -f $(TARGET) marquee_tb.vcd

.PHONY: all compile simulate wave clean
