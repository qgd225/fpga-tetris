# Shared A3 material port + shader, including LUT geometry tables and A2 panels.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root temporary new_ui_a3 synthesis]
file mkdir $output
foreach top {ui_material_atlas ui_mission_layer ui_basic_layer} {
 if {$argc>0 && $top ni $argv} {continue}
 create_project -in_memory -part xc7a35tfgg484-2
 set_property include_dirs [list [file join $root Tetris.srcs sources_1 new]] [current_fileset]
 foreach name {ui_material_atlas ui_mission_layer ui_basic_layer} {read_verilog [file join $root Tetris.srcs sources_1 new ${name}.v]}
 synth_design -mode out_of_context -top $top -part xc7a35tfgg484-2
 create_clock -name pixel -period 13.473 [get_ports clk]
 set data_inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
 set_input_delay -clock pixel -max 2.000 $data_inputs
 set_input_delay -clock pixel -min 0.200 $data_inputs
 set_output_delay -clock pixel -max 2.000 [all_outputs]
 set_output_delay -clock pixel -min 0.200 [all_outputs]
 report_utilization -file [file join $output ${top}_utilization.rpt]
 report_timing_summary -file [file join $output ${top}_timing.rpt]
 report_timing -max_paths 5 -file [file join $output ${top}_paths.rpt]
 write_checkpoint -force [file join $output ${top}.dcp]
 puts "A3_SYNTH_DONE $top"
 close_project
}
puts "A3_ALL_SYNTH_DONE"
