set script_dir [file dirname [file normalize [info script]]]
set ws_dir [file join $script_dir sobel_05_pc_control_display.sdk]
set app_src_dir [file join $script_dir ps_uart_control_bram_app src]

setws $ws_dir

if {[file exists [file join $ws_dir top_hw_platform_0 .project]]} {
    catch {importprojects [file join $ws_dir top_hw_platform_0]}
} else {
    createhw -name top_hw_platform_0 -hwspec [file join $ws_dir top.hdf]
}

if {![file exists [file join $ws_dir ps_uart_control_bram_app_bsp .project]]} {
    createbsp -name ps_uart_control_bram_app_bsp \
        -hwproject top_hw_platform_0 \
        -proc ps7_cortexa9_0 \
        -os standalone
}

if {![file exists [file join $ws_dir ps_uart_control_bram_app .project]]} {
    createapp -name ps_uart_control_bram_app \
        -hwproject top_hw_platform_0 \
        -bsp ps_uart_control_bram_app_bsp \
        -proc ps7_cortexa9_0 \
        -os standalone \
        -lang C \
        -app {Empty Application}

    importsources -name ps_uart_control_bram_app -path $app_src_dir
}

projects -build
exit
