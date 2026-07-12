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
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "SOBEL_05_SYNTH_STATUS=$synth_status"
if {[string first "synth_design Complete" $synth_status] < 0} {
    exit 1
}
close_project
exit

