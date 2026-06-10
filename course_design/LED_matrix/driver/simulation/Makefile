# Makefile for iverilog simulation
TARGET = sim_out
SRC = ../src/led_matrix_top.v tb_led_matrix_top.v
SPI_SRC = ../src/led_spi_slave.v tb_led_spi_slave.v
SPI_TARGET = spi_sim_out
DRIVER_SRC = ../src/led_driver.v tb_driver.v
DRIVER_TARGET = driver_sim_out

all: compile simulate

spi: spi_compile spi_simulate

driver: driver_compile driver_simulate

compile:
	iverilog  -g2005-sv -o $(TARGET) $(SRC)

simulate:
	vvp $(TARGET)

spi_compile: 
	iverilog  -g2005-sv -o $(SPI_TARGET) $(SPI_SRC)

spi_simulate:
	vvp $(SPI_TARGET)

driver_compile: 
	iverilog  -g2005-sv -o $(DRIVER_TARGET) $(DRIVER_SRC)

driver_simulate:
	vvp $(DRIVER_TARGET)

wave:
	gtkwave tb_led_matrix_top.vcd &

clean:
	rm -f $(TARGET) *.vcd

.PHONY: all compile simulate wave clean
