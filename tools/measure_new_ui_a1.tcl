# Standalone A1 texture ROM measurement. Never opens/resets the formal project.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root temporary new_ui_a1]
if {$argc>0} {set output [file normalize [lindex $argv 0]]}
file mkdir [file join $output synthesis]
source [file join $output probes.tcl]
foreach probe $ui_a1_probes {
    lassign $probe top wrapper
    if {$argc>1 && $top ne [lindex $argv 1]} {continue}
    create_project -in_memory -part xc7a35tfgg484-2
    read_verilog [file join $root Tetris.srcs sources_1 new ui_exact_tile_rom.v]
    read_verilog [file join $root Tetris.srcs sources_1 new ui_font_5x7.v]
    read_verilog $wrapper
    synth_design -mode out_of_context -top $top -part xc7a35tfgg484-2
    create_clock -name pixel -period 13.473 [get_ports clk]
    report_utilization -file [file join $output synthesis ${top}_utilization.rpt]
    report_timing_summary -file [file join $output synthesis ${top}_timing.rpt]
    report_timing -max_paths 5 -file [file join $output synthesis ${top}_paths.rpt]
    write_checkpoint -force [file join $output synthesis ${top}.dcp]
    puts "A1_SYNTH_PROBE_DONE $top"
    close_project
}
puts "A1_ALL_SYNTH_PROBES_DONE"
