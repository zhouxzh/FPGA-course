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

ifeq ($(WIDTH)x$(HEIGHT),128x72)
INPUT_HEX ?= data/input_rgb.hex
else
INPUT_HEX ?= $(BUILD)/input_rgb.hex
endif

PGM_OUT   ?= $(BUILD)/sobel_out.pgm
INPUT_PNG ?= $(BUILD)/input_rgb.png
SOBEL_PNG ?= $(BUILD)/sobel_out.png

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
	-DBAUD_RATE=$(BAUD_RATE) \
	-DINPUT_RGB_HEX=\"$(INPUT_HEX)\" \
	-DOUTPUT_PGM=\"$(PGM_OUT)\" \
	-DVCD_FILE=\"$(VCD_OUT)\"

.PHONY: all data compile sim images wave clean

all: sim

data: $(BUILD)
	$(PYTHON) tools/gen_input_rgb.py --width $(WIDTH) --height $(HEIGHT) --output $(INPUT_HEX)

$(BUILD):
	mkdir -p $(BUILD)

compile: data $(BUILD)
	$(IVERILOG) -g2005-sv $(DEFINES) -o $(VVP_OUT) $(TB) $(RTL)

sim: compile
	$(VVP) $(VVP_OUT)
	$(PYTHON) tools/convert_images.py --width $(WIDTH) --height $(HEIGHT) --input-rgb $(INPUT_HEX) --sobel-pgm $(PGM_OUT) --input-png $(INPUT_PNG) --sobel-png $(SOBEL_PNG)

images: $(BUILD)
	$(PYTHON) tools/convert_images.py --width $(WIDTH) --height $(HEIGHT) --input-rgb $(INPUT_HEX) --sobel-pgm $(PGM_OUT) --input-png $(INPUT_PNG) --sobel-png $(SOBEL_PNG)

wave:
	$(GTKWAVE) $(VCD_OUT) &

clean:
	rm -rf $(BUILD) data/sobel_out.pgm data/input_rgb.png data/sobel_out.png
