# Module-level screening only; accepted changes still require a full routed build.
set root [file normalize [file join [file dirname [info script]] ..]]
if {$argc != 2} {error "Usage: screen_playfield.tcl source.v output_directory"}
set rtl [file normalize [lindex $argv 0]]
set output [file normalize [lindex $argv 1]]
file mkdir $output
create_project -in_memory -part xc7a35tfgg484-2
read_verilog [file join $root Tetris.srcs sources_1 ip Tetromino Tetromino_stub.v]
read_verilog [file join $root Tetris.srcs sources_1 ip weiyibiao weiyibiao_stub.v]
read_verilog [file join $root Tetris.srcs sources_1 new solo_hint.v]
read_verilog $rtl
synth_design -top Playfield -mode out_of_context -part xc7a35tfgg484-2 -directive AreaOptimized_high -control_set_opt_threshold 1
create_clock -period 13.468 [get_ports Clk_74M]
report_utilization -file [file join $output utilization.rpt]
report_utilization -hierarchical -file [file join $output hierarchy.rpt]
puts "SCREEN_COMPLETE $output"
