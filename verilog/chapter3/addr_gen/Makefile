TARGET = tb_addr_gen
SRC = addr_gen.v tb_addr_gen.v

all: compile run

compile:
	iverilog -g2005-sv -o $(TARGET).vvp $(SRC)

run:
	vvp -n $(TARGET).vvp
	gtkwave $(TARGET).vcd &

clean:
	rm -f *.vvp *.vcd

.PHONY: all compile run clean