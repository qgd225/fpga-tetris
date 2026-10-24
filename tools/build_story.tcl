# 单一工程内构建候选；所有检查通过后才更新唯一发布 bit。
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
set round story_r1
if {$argc > 0} {set round [lindex $argv 0]}
if {![regexp {^story_[a-zA-Z0-9_]+$} $round]} {error "Invalid round name"}
set output [file join $root docs reports $round]
file mkdir $output
open_project Tetris.xpr
foreach name {story_controller bin_to_bcd hud_text hud_font_rom core_renderer scene_sprite_rom audio_synth story_comms voice_player voice_adpcm_rom} {
    set source [file join $root Tetris.srcs sources_1 new ${name}.v]
    if {[file isfile $source] && [llength [get_files -quiet $source]] == 0} {
        add_files -norecurse $source
    }
}
set hook [get_property STEPS.WRITE_BITSTREAM.TCL.POST [get_runs impl_1]]
set_property STEPS.WRITE_BITSTREAM.TCL.POST {} [get_runs impl_1]
set status [catch {
    update_compile_order -fileset sources_1
    reset_run synth_1
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
    open_run impl_1
    report_utilization -file [file join $output utilization.rpt]
    report_utilization -hierarchical -hierarchical_depth 6 -file [file join $output hierarchy.rpt]
    report_timing_summary -file [file join $output timing.rpt]
    report_route_status -file [file join $output route.rpt]
    report_drc -file [file join $output drc.rpt]
    report_bus_skew -file [file join $output bus_skew.rpt]
    source [file join $root tools check_lutram_pins.tcl]
    check_lutram_pins [file join $output lutram_pins.rpt]
    if {[llength [get_timing_paths -quiet -slack_lesser_than 0 -delay_type max]] > 0} {error "Setup timing failed"}
    if {[llength [get_timing_paths -quiet -slack_lesser_than 0 -delay_type min]] > 0} {error "Hold timing failed"}
    source [file join $root tools publish_bitstream.tcl]
    publish_bitstream [file join $root Tetris.runs impl_1 Tetris.bit] $root
    puts "STORY_BUILD_PASS $round"
} problem]
set_property STEPS.WRITE_BITSTREAM.TCL.POST $hook [get_runs impl_1]
close_project
if {$status} {error $problem}
