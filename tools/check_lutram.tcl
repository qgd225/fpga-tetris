# Build in a separate project so the published bitstream and original runs survive.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root Tetris.runs lutram_final]
if {$argc > 0} {set output [file normalize [lindex $argv 0]]}
file mkdir $output
open_project [file join $root Tetris.xpr]
save_project_as Tetris_lutram $output -force
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AreaOptimized_high [get_runs synth_1]
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "LUTRAM synthesis failed"}
open_run synth_1
report_utilization -file [file join $output utilization_synth.rpt]
report_utilization -hierarchical -hierarchical_depth 5 -file [file join $output hierarchy_synth.rpt]
source [file join $root tools check_lutram_pins.tcl]
check_lutram_pins [file join $output lutram_pins_synth.rpt]
write_checkpoint -force [file join $output synthesized.dcp]
close_design
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "LUTRAM implementation failed"}
open_run impl_1
report_utilization -file [file join $output utilization_routed.rpt]
report_timing_summary -file [file join $output timing_routed.rpt]
report_route_status -file [file join $output route_status.rpt]
check_lutram_pins [file join $output lutram_pins_routed.rpt]
write_checkpoint -force [file join $output routed.dcp]
puts "LUTRAM_BUILD_COMPLETE $output"
close_project
