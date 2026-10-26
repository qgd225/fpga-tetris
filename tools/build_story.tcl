# 单一工程内构建候选；所有检查通过后才更新唯一发布 bit。
set root [file normalize [file join [file dirname [info script]] ..]]
file mkdir [file join $root temporary]
cd [file join $root temporary]
set round story_r2a
if {$argc > 0} {set round [lindex $argv 0]}
set publish 0
if {$argc > 1} {
    if {[lindex $argv 1] ne "publish"} {error "Second argument must be publish"}
    set publish 1
}
source [file join $root tools project_policy.tcl]
set timing_limits [project_timing_limits $root]
set timing_target [dict get $timing_limits TIMING_MIN_WNS_NS]
proc used_resource {text name} {
    if {![regexp [format {\|\s*%s\s*\|\s*([0-9.]+)} $name] $text -> value]} {
        error "Missing resource $name"
    }
    return $value
}
if {![regexp {^story_[a-zA-Z0-9_]+$} $round]} {error "Invalid round name"}
set output [file join $root docs reports $round]
file mkdir $output
set gate_snapshot [open [file join $output rules-at-build.md] w]
fconfigure $gate_snapshot -encoding utf-8 -translation lf
set rules_file [open [file join $root AGENTS.md] r]
fconfigure $rules_file -encoding utf-8
puts -nonewline $gate_snapshot [read $rules_file]
close $rules_file
close $gate_snapshot
puts [exec python [file join $root tools build_story_assets.py]]
if {[file isfile [file join $root assets story_voice.json]]} {
    puts [exec python [file join $root tools prepare_story_voice.py]]
    puts [exec python [file join $root tools build_voice_assets.py]]
}
open_project [file join $root Tetris.xpr]
foreach stale {voice_v0.mem voice_v0_config.vh} {set entries [get_files -quiet *$stale];if {[llength $entries]} {remove_files $entries}}
set_property include_dirs [list [file join $root Tetris.srcs sources_1 new]] [get_filesets sources_1]
foreach name {story_debris story_pixel_frontend story_pixel_mapper story_ui story_scene story_presentation story_feedback story_controller bin_to_bcd hud_text hud_font_rom core_renderer scene_sprite_rom audio_synth audio_mixer ima_adpcm_decoder story_comms voice_player voice_adpcm_rom} {
    set source [file join $root Tetris.srcs sources_1 new ${name}.v]
    if {[file isfile $source] && [llength [get_files -quiet $source]] == 0} {
        add_files -norecurse $source
    }
}
foreach name {game_mode_params.vh story_debris_percent.mem story_debris.mem story_font.mem story_sprites.mem story_voice.mem story_voice_config.vh story_voice_ids.vh story_audio_priority.vh story_layout.vh story_text_ids.vh story_palette.vh} {
    set source [file join $root Tetris.srcs sources_1 new $name]
    if {[file isfile $source] && [llength [get_files -quiet $source]] == 0} {add_files -norecurse $source}
}
close_project
open_project [file join $root Tetris.xpr]
puts [exec python [file join $root tools story_build_manifest.py] write [file join $output source-manifest.json]]
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
    set utilization [report_utilization -return_string]
    set luts [used_resource $utilization {Slice LUTs}]
    set registers [used_resource $utilization {Slice Registers}]
    set bram [used_resource $utilization {Block RAM Tile}]
    set latches [used_resource $utilization {Register as Latch}]
    set dsp [used_resource $utilization {DSPs}]
    set setup_path [get_timing_paths -quiet -delay_type max -max_paths 1]
    set hold_path [get_timing_paths -quiet -delay_type min -max_paths 1]
    if {[llength $setup_path] != 1 || [llength $hold_path] != 1} {error "Missing timing paths"}
    set wns [get_property SLACK $setup_path]
    set whs [get_property SLACK $hold_path]
    set green [expr {$wns >= $timing_target && $whs >= $timing_target}]
    set timing [verify_project_timing $root]
    set tns [dict get $timing TNS]
    set ths [dict get $timing THS]
    set result [open [file join $output gate-summary.txt] w]
    puts $result "LUT=$luts REGISTERS=$registers BRAM=$bram LATCHES=$latches DSP=$dsp"
    puts $result "WNS=$wns WHS=$whs TNS=$tns THS=$ths TARGET=$timing_target GREEN=$green RESOURCE_POLICY=DEVICE_CAPACITY PUBLISH_REQUESTED=$publish"
    close $result
    report_timing -max_paths 20 -file [file join $output setup_paths.rpt]
    if {!$green} {error "Candidate timing margin failed"}

} problem]
set_property STEPS.WRITE_BITSTREAM.TCL.POST $hook [get_runs impl_1]
close_project
puts [exec python [file join $root tools story_build_manifest.py] verify [file join $output source-manifest.json]]
if {$status} {error $problem}
if {$publish} {
        source [file join $root tools publish_bitstream.tcl]
        publish_bitstream [file join $root Tetris.runs impl_1 Tetris.bit] $root
    } else {
        puts "STORY_CANDIDATE_ONLY: published bitstream unchanged"
    }
    puts "STORY_BUILD_PASS $round"
