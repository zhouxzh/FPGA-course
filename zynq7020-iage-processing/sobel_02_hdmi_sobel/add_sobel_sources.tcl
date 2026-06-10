set project_dir [file dirname [file normalize [info script]]]
set src_dir [file join $project_dir "sobel_02_hdmi_sobel.srcs" "sources_1" "new"]

set files [list [file join $src_dir "top.v"]]

foreach file_path $files {
    if {[llength [get_files -quiet $file_path]] == 0} {
        add_files -norecurse -fileset sources_1 $file_path
    }
    set_property used_in_synthesis true [get_files $file_path]
    set_property used_in_implementation true [get_files $file_path]
    set_property used_in_simulation true [get_files $file_path]
}

set_property top top [current_fileset]
set_property include_dirs $src_dir [current_fileset]
update_compile_order -fileset sources_1

if {[llength [get_runs -quiet synth_1]] != 0} {
    reset_run synth_1
}
