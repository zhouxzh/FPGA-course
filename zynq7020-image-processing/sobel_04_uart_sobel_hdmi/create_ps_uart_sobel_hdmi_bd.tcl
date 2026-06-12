# Create the PS UART + AXI BRAM block design for step 4.
# HDMI logic stays in RTL top.v to avoid module-reference OOC IP conflicts.
#
# Run from Vivado Tcl Console after opening sobel_04_uart_sobel_hdmi.xpr:
#
#   cd D:/Github/FPGA-course/zynq7020-image-processing/sobel_04_uart_sobel_hdmi
#   source create_ps_uart_sobel_hdmi_bd.tcl

set bd_name ps_uart_bram_hdmi
set script_dir [file dirname [file normalize [info script]]]
set src_dir [file join $script_dir sobel_04_uart_sobel_hdmi.srcs sources_1 new]

proc set_config_if_supported {obj config_pairs} {
    set supported [list_property $obj]
    foreach {key value} $config_pairs {
        set prop_name CONFIG.$key
        if {[lsearch -exact $supported $prop_name] >= 0} {
            if {[catch {set_property $prop_name $value $obj} msg]} {
                puts "Warning: failed to set $prop_name to {$value}: $msg"
            }
        }
    }
}

proc xml_unescape {value} {
    return [string map [list "&lt;" "<" "&gt;" ">" "&amp;" "&"] $value]
}

proc apply_ps7_config_from_bd {obj bd_path} {
    if {![file exists $bd_path]} {
        puts "PS7 reference BD not found: $bd_path"
        return
    }

    set fp [open $bd_path r]
    set xml [read $fp]
    close $fp

    set supported [list_property $obj]
    set matches [regexp -all -inline {<spirit:configurableElementValue spirit:referenceId="(PCW_[^"]+)">([^<]*)</spirit:configurableElementValue>} $xml]
    set applied 0

    for {set i 0} {$i < [llength $matches]} {incr i 3} {
        set key [lindex $matches [expr {$i + 1}]]
        set value [xml_unescape [lindex $matches [expr {$i + 2}]]]
        set prop_name CONFIG.$key
        if {[lsearch -exact $supported $prop_name] >= 0} {
            if {![catch {set_property $prop_name $value $obj}]} {
                incr applied
            }
        }
    }

    puts "Imported $applied PS7 config values from $bd_path"
}

proc ensure_file_added {file_path} {
    if {[llength [get_files -quiet $file_path]] == 0} {
        add_files -norecurse $file_path
    }
    set file_obj [get_files -quiet $file_path]
    if {[llength $file_obj] != 0} {
        catch {set_property is_enabled true $file_obj}
        catch {set_property used_in_synthesis true $file_obj}
        catch {set_property used_in_implementation true $file_obj}
    }
}

proc remove_existing_bd_artifacts {bd_name script_dir} {
    if {[llength [get_bd_designs -quiet $bd_name]] != 0} {
        close_bd_design [get_bd_designs $bd_name]
    }

    foreach f [get_files -quiet *${bd_name}.bd] {
        catch {remove_files $f}
    }
    foreach f [get_files -quiet *${bd_name}_wrapper.v] {
        catch {remove_files $f}
    }

    foreach dir [list \
        [file join $script_dir sobel_04_uart_sobel_hdmi.srcs sources_1 bd $bd_name] \
        [file join $script_dir sobel_04_uart_sobel_hdmi.gen sources_1 bd $bd_name] \
        [file join $script_dir sobel_04_uart_sobel_hdmi.ip_user_files bd $bd_name] \
    ] {
        if {[file exists $dir]} {
            file delete -force $dir
        }
    }
}

proc generate_bd_wrapper {bd_name} {
    set bd_file [get_files -quiet ${bd_name}.bd]
    if {[llength $bd_file] == 0} {
        error "Cannot find block design file ${bd_name}.bd"
    }

    generate_target all $bd_file
    set wrapper [make_wrapper -files $bd_file -top -force]
    if {[string trim $wrapper] eq ""} {
        error "make_wrapper did not return a wrapper path for ${bd_name}.bd"
    }
    if {![file exists $wrapper]} {
        error "Generated wrapper file not found: $wrapper"
    }
    if {[llength [get_files -quiet $wrapper]] == 0} {
        add_files -norecurse $wrapper
    }
    update_compile_order -fileset sources_1
    puts "Generated wrapper ${bd_name}_wrapper at $wrapper"
}

set rtl_files [list \
    [file join $src_dir top.v] \
    [file join $src_dir hdmi_bram_display.v] \
    [file join $src_dir rgb_to_gray.v] \
    [file join $src_dir sobel_core.v] \
    [file join $src_dir hdmi_bram_sobel_display.v] \
    [file join $src_dir hdmi_pl_top.v] \
]

foreach f $rtl_files {
    ensure_file_added $f
}
update_compile_order -fileset sources_1

remove_existing_bd_artifacts $bd_name $script_dir

create_bd_design $bd_name

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable"} \
    [get_bd_cells processing_system7_0]

set ps7_ref_bd [file normalize [file join $script_dir .. .. FPGA_Program exp15_bram_test bram_test.srcs sources_1 bd top top.bd]]
apply_ps7_config_from_bd [get_bd_cells processing_system7_0] $ps7_ref_bd

set_config_if_supported [get_bd_cells processing_system7_0] [list \
    PCW_USE_M_AXI_GP0 1 \
    PCW_USE_M_AXI_GP1 0 \
    PCW_USE_S_AXI_GP0 0 \
    PCW_USE_S_AXI_GP1 0 \
    PCW_USE_S_AXI_ACP 0 \
    PCW_USE_S_AXI_HP0 0 \
    PCW_USE_S_AXI_HP1 0 \
    PCW_USE_S_AXI_HP2 0 \
    PCW_USE_S_AXI_HP3 0 \
    PCW_USE_FABRIC_INTERRUPT 0 \
    PCW_IRQ_F2P_INTR 0 \
    PCW_EN_CLK0_PORT 1 \
    PCW_EN_RST0_PORT 1 \
    PCW_FPGA0_PERIPHERAL_FREQMHZ 50 \
    PCW_EN_DDR 1 \
    PCW_UIPARAM_DDR_ENABLE 1 \
    PCW_UIPARAM_DDR_ADV_ENABLE 0 \
    PCW_UIPARAM_DDR_FREQ_MHZ 533.333333 \
    PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
    PCW_UIPARAM_DDR_BUS_WIDTH {32 Bit} \
    PCW_UIPARAM_DDR_BL 8 \
    PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
    PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
    PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL 1 \
    PCW_UIPARAM_DDR_TRAIN_READ_GATE 1 \
    PCW_UIPARAM_DDR_TRAIN_DATA_EYE 1 \
    PCW_UIPARAM_DDR_CLOCK_STOP_EN 0 \
    PCW_UIPARAM_DDR_USE_INTERNAL_VREF 0 \
    PCW_EN_UART1 1 \
    PCW_EN_UART0 0 \
    PCW_UART1_PERIPHERAL_ENABLE 1 \
    PCW_UART1_UART1_IO {MIO 48 .. 49} \
    PCW_UART1_GRP_FULL_ENABLE 0 \
    PCW_UART1_BAUD_RATE 115200 \
    PCW_UART_PERIPHERAL_VALID 1 \
    PCW_UART_PERIPHERAL_FREQMHZ 100 \
    PCW_EN_EMIO_UART1 0 \
    PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
    PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_50M
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0

set_config_if_supported [get_bd_cells axi_smc] [list \
    NUM_MI 1 \
    NUM_SI 1 \
]

set_config_if_supported [get_bd_cells axi_bram_ctrl_0] [list \
    DATA_WIDTH 32 \
    SINGLE_PORT_BRAM 1 \
    ECC_TYPE 0 \
]

set_config_if_supported [get_bd_cells blk_mem_gen_0] [list \
    Memory_Type True_Dual_Port_RAM \
    Enable_A Always_Enabled \
    Enable_B Use_ENB_Pin \
    Use_RSTA_Pin false \
    Use_RSTB_Pin true \
    Use_Byte_Write_Enable true \
    Byte_Size 8 \
    Write_Width_A 32 \
    Read_Width_A 32 \
    Write_Depth_A 16384 \
    Write_Width_B 32 \
    Read_Width_B 32 \
    Read_Depth_B 16384 \
    Operating_Mode_A WRITE_FIRST \
    Operating_Mode_B READ_FIRST \
    Port_B_Clock 74.25 \
    EN_SAFETY_CKT false \
]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins axi_smc/aclk] \
    [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
    [get_bd_pins rst_ps7_0_50M/slowest_sync_clk]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins rst_ps7_0_50M/ext_reset_in]

connect_bd_net [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] \
    [get_bd_pins axi_smc/aresetn] \
    [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins axi_smc/S00_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_smc/M00_AXI] \
    [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] \
    [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

set bram_portb_clk [create_bd_port -dir I -type clk BRAM_PORTB_clk]
set_property CONFIG.FREQ_HZ 74250000 $bram_portb_clk
set bram_portb_rst [create_bd_port -dir I -type rst BRAM_PORTB_rst]
set_property CONFIG.POLARITY ACTIVE_HIGH $bram_portb_rst
set bram_portb_en [create_bd_port -dir I BRAM_PORTB_en]
set bram_portb_we [create_bd_port -dir I -from 3 -to 0 BRAM_PORTB_we]
set bram_portb_addr [create_bd_port -dir I -from 31 -to 0 BRAM_PORTB_addr]
set bram_portb_din [create_bd_port -dir I -from 31 -to 0 BRAM_PORTB_din]
set bram_portb_dout [create_bd_port -dir O -from 31 -to 0 BRAM_PORTB_dout]

connect_bd_net [get_bd_ports BRAM_PORTB_clk]  [get_bd_pins blk_mem_gen_0/clkb]
connect_bd_net [get_bd_ports BRAM_PORTB_rst]  [get_bd_pins blk_mem_gen_0/rstb]
connect_bd_net [get_bd_ports BRAM_PORTB_en]   [get_bd_pins blk_mem_gen_0/enb]
connect_bd_net [get_bd_ports BRAM_PORTB_we]   [get_bd_pins blk_mem_gen_0/web]
connect_bd_net [get_bd_ports BRAM_PORTB_addr] [get_bd_pins blk_mem_gen_0/addrb]
connect_bd_net [get_bd_ports BRAM_PORTB_din]  [get_bd_pins blk_mem_gen_0/dinb]
connect_bd_net [get_bd_ports BRAM_PORTB_dout] [get_bd_pins blk_mem_gen_0/doutb]

assign_bd_address
set bram_seg [get_bd_addr_segs -quiet processing_system7_0/Data/SEG_axi_bram_ctrl_0_Mem0]
if {[llength $bram_seg] != 0} {
    set_property offset 0x40000000 $bram_seg
    set_property range 64K $bram_seg
}

validate_bd_design
save_bd_design

generate_bd_wrapper $bd_name
set_property top top [current_fileset]
update_compile_order -fileset sources_1

puts "Created $bd_name. BRAM base address is expected to be 0x40000000, range 64KB. Project top is top."
