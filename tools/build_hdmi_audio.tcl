set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
open_project Tetris.xpr
set_property CONFIG.USE_LOCKED true [get_ips hdmi_pll]
reset_run synth_1
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreArea [get_runs impl_1]
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} { error "Synthesis failed" }
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "Implementation failed" }
open_run impl_1
report_utilization -file hdmi_audio_utilization.rpt
report_timing_summary -file hdmi_audio_timing.rpt
report_bus_skew -file hdmi_audio_bus_skew.rpt
report_route_status -file hdmi_audio_route.rpt
report_drc -file hdmi_audio_drc.rpt
if {[llength [get_timing_paths -quiet -slack_lesser_than 0 -delay_type max]] > 0} { error "Setup timing failed" }
if {[llength [get_timing_paths -quiet -slack_lesser_than 0 -delay_type min]] > 0} { error "Hold timing failed" }
file copy -force Tetris.runs/impl_1/Tetris.bit Tetris_hdmi_audio.bit
close_project
