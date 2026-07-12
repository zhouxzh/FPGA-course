open_project ./sobel_04_uart_sobel_hdmi.xpr
update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
puts "SOBEL_04_IMPL_STATUS=$impl_status"
if {[string first "write_bitstream Complete" $impl_status] < 0} {
    exit 1
}
close_project
exit
