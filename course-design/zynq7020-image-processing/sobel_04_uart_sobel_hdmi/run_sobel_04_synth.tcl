open_project ./sobel_04_uart_sobel_hdmi.xpr
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "SOBEL_04_SYNTH_STATUS=$synth_status"
if {[string first "synth_design Complete" $synth_status] < 0} {
    exit 1
}
close_project
exit
