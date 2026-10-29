# A2 connected common-layer measurements, without opening/resetting Tetris.xpr.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root temporary new_ui_a2 synthesis]
file mkdir $output
foreach top {ui_panel_atlas ui_basic_layer ui_text_raster} {
 if {$argc>0 && $top ni $argv} {continue}
 create_project -in_memory -part xc7a35tfgg484-2
 set_property include_dirs [list [file join $root Tetris.srcs sources_1 new]] [current_fileset]
 foreach name {ui_font_5x7 ui_text_raster ui_panel_atlas ui_basic_layer} {
  read_verilog [file join $root Tetris.srcs sources_1 new ${name}.v]
 }
 synth_design -mode out_of_context -top $top -part xc7a35tfgg484-2
 create_clock -name pixel -period 13.473 [get_ports clk]
 # Explicit neighboring-register budget for the standalone interface estimate.
 # This is an OOC model, not a replacement for routed whole-design timing.
 set data_inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
 set_input_delay -clock pixel -max 2.000 $data_inputs
 set_input_delay -clock pixel -min 0.200 $data_inputs
 set_output_delay -clock pixel -max 2.000 [all_outputs]
 set_output_delay -clock pixel -min 0.200 [all_outputs]
 report_utilization -file [file join $output ${top}_utilization.rpt]
 report_timing_summary -file [file join $output ${top}_timing.rpt]
 report_timing -max_paths 5 -file [file join $output ${top}_paths.rpt]
 write_checkpoint -force [file join $output ${top}.dcp]
 puts "A2_SYNTH_DONE $top"
 close_project
}
puts "A2_ALL_SYNTH_DONE"
