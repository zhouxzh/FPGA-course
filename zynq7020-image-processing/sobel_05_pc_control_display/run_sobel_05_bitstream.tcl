open_project ./sobel_05_pc_control_display.xpr
update_compile_order -fileset sources_1

foreach run_name [get_runs] {
    set run_status [get_property STATUS $run_name]
    if {[string first "ERROR" $run_status] >= 0 ||
        [string first "Failed" $run_status] >= 0 ||
        [string first "fail" $run_status] >= 0} {
        reset_run $run_name
    }
}

reset_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
puts "SOBEL_05_IMPL_STATUS=$impl_status"
if {[string first "write_bitstream Complete" $impl_status] < 0} {
    exit 1
}
close_project
exit

