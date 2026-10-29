# Formal whole-design synthesis; outputs remain under the authorized workspace.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root temporary ui_polish_20261029 whole_synth]
file mkdir $output
open_project [file join $root Tetris.xpr]
source [file join $root tools register_new_ui.tcl]
set_property include_dirs [list [file join $root Tetris.srcs sources_1 new]] [get_filesets sources_1]
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "FINAL_UI_SYNTH_FAILED"}
open_run synth_1
# Resolve unused legacy IP outputs before testing physical capacity.
opt_design
report_utilization -file [file join $output utilization.rpt]
report_utilization -hierarchical -hierarchical_depth 6 -file [file join $output hierarchy.rpt]
report_timing_summary -file [file join $output timing.rpt]
puts "FINAL_UI_WHOLE_SYNTH_DONE"
close_project
