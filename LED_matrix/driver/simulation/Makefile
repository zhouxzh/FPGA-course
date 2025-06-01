# Makefile for iverilog simulation
TARGET = sim_out
SRC = ../src/driver.v driver_tb.v

all: compile simulate

compile:
	iverilog  -g2005-sv -o $(TARGET) $(SRC)

simulate:
	vvp $(TARGET)

wave:
	gtkwave led_matrix_driver_spi_tb.vcd &

clean:
	rm -f $(TARGET) led_matrix_driver_spi_tb.vcd

.PHONY: all compile simulate wave clean
