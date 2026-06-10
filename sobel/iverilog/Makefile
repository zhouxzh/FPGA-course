IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3
GTKWAVE  ?= gtkwave

WIDTH     ?= 128
HEIGHT    ?= 72
CLK_FREQ  ?= 12000000
BAUD_RATE ?= 1000000

TOP    = sobel_system_tb
BUILD  = build
VVP_OUT = $(BUILD)/$(TOP).vvp
VCD_OUT = $(BUILD)/$(TOP).vcd

RTL = \
	rtl/uart_rx.v \
	rtl/image_frame_rx.v \
	rtl/rgb_to_gray.v \
	rtl/sobel_core.v \
	rtl/video_stream_model.v \
	rtl/sobel_system.v

TB = tb/sobel_system_tb.v

DEFINES = \
	-DIMG_WIDTH=$(WIDTH) \
	-DIMG_HEIGHT=$(HEIGHT) \
	-DCLK_FREQ=$(CLK_FREQ) \
	-DBAUD_RATE=$(BAUD_RATE)

.PHONY: all data compile sim images wave clean

all: sim

data:
	$(PYTHON) tools/gen_input_rgb.py --width $(WIDTH) --height $(HEIGHT) --output data/input_rgb.hex

$(BUILD):
	mkdir -p $(BUILD)

compile: data $(BUILD)
	$(IVERILOG) -g2005-sv $(DEFINES) -o $(VVP_OUT) $(TB) $(RTL)

sim: compile
	$(VVP) $(VVP_OUT)
	$(PYTHON) tools/convert_images.py --width $(WIDTH) --height $(HEIGHT)

images:
	$(PYTHON) tools/convert_images.py --width $(WIDTH) --height $(HEIGHT)

wave:
	$(GTKWAVE) $(VCD_OUT) &

clean:
	rm -rf $(BUILD) data/input_rgb.hex data/sobel_out.pgm data/input_rgb.png data/sobel_out.png
