# Resume the verified final synthesis; never publish before Python evidence checks.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root temporary ui_polish_20261029 routed]
file mkdir $output
open_project [file join $root Tetris.xpr]
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Missing completed synthesis"}
puts [exec python [file join $root tools story_build_manifest.py] write [file join $output source-manifest.json]]
file copy -force [file join $root Tetris.xpr] [file join $output project-at-build.xpr]
file copy -force [file join $root docs AGENTS.md] [file join $output rules-at-build.md]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Final implementation failed"}
open_run impl_1
report_utilization -file [file join $output utilization.rpt]
report_utilization -hierarchical -hierarchical_depth 6 -file [file join $output hierarchy.rpt]
report_timing_summary -file [file join $output timing.rpt]
report_timing -max_paths 20 -file [file join $output paths.rpt]
report_route_status -file [file join $output route.rpt]
report_drc -file [file join $output drc.rpt]
report_cdc -file [file join $output cdc.rpt]
report_bus_skew -file [file join $output bus_skew.rpt]
source [file join $root tools check_lutram_pins.tcl]
check_lutram_pins [file join $output lutram_pins.rpt]
source [file join $root tools project_policy.tcl]
set timing [verify_project_timing $root]
foreach mode {max min} {
 if {[get_property SLACK [get_timing_paths -delay_type $mode -max_paths 1]]<0} {error "NEGATIVE_EXACT_SLACK $mode"}
}
set skew_file [open [file join $output bus_skew.rpt] r];set skew_text [read $skew_file];close $skew_file
foreach expected {packets/wg_reg packets/rg_reg word_transmit.words/wg_reg word_transmit.words/rg_reg} {
 if {[string first $expected $skew_text]<0} {error "MISSING_GRAY_BUS_SKEW $expected"}
}
if {[string match *VIOLATED* $skew_text]} {error "GRAY_BUS_SKEW_FAILED"}
set critical {}
foreach issue [get_drc_violations -quiet] {
 if {[get_property SEVERITY $issue] in {Error {Critical Warning}}} {lappend critical $issue}
}
if {[llength $critical]} {error "FINAL_DRC_FAILED $critical"}

set util [report_utilization -return_string]
if {![regexp {\|\s*Slice LUTs\*?\s*\|\s*([0-9]+)} $util -> lut]} {error "Missing LUT count"}
if {$lut>20000} {error "FINAL_LUT_RESERVE_FAILED $lut"}
file copy -force [file join $root Tetris.runs impl_1 Tetris.bit] [file join $output Tetris.bit]
write_checkpoint -force [file join $output final_routed.dcp]
set f [open [file join $output gate-summary.txt] w];puts $f "LUT=$lut FREE_LUT=[expr {20800-$lut}] TIMING=$timing";close $f
close_project
puts [exec python [file join $root tools story_build_manifest.py] verify [file join $output source-manifest.json]]
puts FINAL_UI_ROUTED_CANDIDATE_PASS
