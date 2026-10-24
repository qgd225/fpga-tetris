# Module-level comparison with black-box ROM interfaces, using the same directive.
set root [file normalize [file join [file dirname [info script]] ..]]
if {$argc != 2} {error "Usage: screen_frame.tcl frame.v output_directory"}
set rtl [file normalize [lindex $argv 0]]
set output [file normalize [lindex $argv 1]]
file mkdir $output
create_project -in_memory -part xc7a35tfgg484-2
foreach ip {Tetromino weiyibiao letter number_1} {
    foreach stub [glob [file join $root Tetris.srcs sources_1 ip $ip *_stub.v]] {read_verilog $stub}
}
foreach name {Playfield Playfield_pixel_mapper Playfield_speed_control Playfield_hold_controller Playfield_ghost_scanner Playfield_edge solo_hint Next_piece hold_piece timer scoring level game_over choose_menu} {
    read_verilog [file join $root Tetris.srcs sources_1 new $name.v]
}
read_verilog $rtl
read_verilog [file join $root Tetris.srcs sources_1 new frame_background.v]
synth_design -top frame -mode out_of_context -part xc7a35tfgg484-2 -directive AreaOptimized_high -control_set_opt_threshold 1
create_clock -period 13.468 [get_ports Clk_74M]
report_utilization -file [file join $output utilization.rpt]
report_utilization -hierarchical -file [file join $output hierarchy.rpt]
puts "SCREEN_COMPLETE $output"
