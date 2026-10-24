# 单一工程内构建候选；所有检查通过后才更新唯一发布 bit。
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
set round story_r2a
if {$argc > 0} {set round [lindex $argv 0]}
set publish 0
if {$argc > 1} {
    if {[lindex $argv 1] ne "publish"} {error "Second argument must be publish"}
    set publish 1
}
# 数值从计划门禁唯一限额表读取，避免构建脚本另存一套上限。
set gate_file [open [file join $root docs story-execution-gates.md] r]
fconfigure $gate_file -encoding utf-8
set gates [read $gate_file]
close $gate_file
proc gate_numbers {text key} {
    foreach line [split $text "\n"] {
        if {[regexp [format {^\| %s \|} $key] $line]} {
            set value [lindex [split $line |] 2]
            return [string map {, {}} [regexp -all -inline {[0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?} $value]]
        }
    }
    error "Missing gate $key"
}
set timing_target [lindex [gate_numbers $gates T1] 0]
set lut_target [lindex [gate_numbers $gates R1] 0]
set lut_limit [lindex [gate_numbers $gates R1] 1]
set visual_limit [lindex [gate_numbers $gates R2] 2]
set bram_target [lindex [gate_numbers $gates R5] 0]
set bram_limit [lindex [gate_numbers $gates R5] 1]
set register_values [gate_numbers $gates R7]
set register_limit [expr {[lindex $register_values 0]+[lindex $register_values 1]}]
proc used_resource {text name} {
    if {![regexp [format {\|\s*%s\s*\|\s*([0-9.]+)} $name] $text -> value]} {
        error "Missing resource $name"
    }
    return $value
}
if {![regexp {^story_[a-zA-Z0-9_]+$} $round]} {error "Invalid round name"}
set output [file join $root docs reports $round]
file mkdir $output
puts [exec python [file join $root tools story_build_manifest.py] write [file join $output source-manifest.json]]
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
    puts [exec python [file join $root tools story_build_manifest.py] verify [file join $output source-manifest.json]]
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
    set budget [expr {$luts <= $lut_limit && $bram <= $bram_limit && $registers <= $register_limit && $latches <= 12 && $dsp == 0}]
    set target_budget [expr {$luts <= $lut_target && $bram <= $bram_target}]
    set visual_budget [expr {![regexp {^story_r[23]} $round] || $luts <= $visual_limit}]
    set result [open [file join $output gate-summary.txt] w]
    puts $result "LUT=$luts REGISTERS=$registers BRAM=$bram LATCHES=$latches DSP=$dsp"
    puts $result "WNS=$wns WHS=$whs TARGET=$timing_target GREEN=$green BUDGET=$budget TARGET_BUDGET=$target_budget VISUAL_BUDGET=$visual_budget PUBLISH_REQUESTED=$publish"
    close $result
    report_timing -max_paths 20 -file [file join $output setup_paths.rpt]
    if {$publish} {
        if {!$green || !$budget || !$target_budget || !$visual_budget} {error "Publish blocked by story gates"}
        source [file join $root tools publish_bitstream.tcl]
        publish_bitstream [file join $root Tetris.runs impl_1 Tetris.bit] $root
    } else {
        puts "STORY_CANDIDATE_ONLY: published bitstream unchanged"
    }
    puts "STORY_BUILD_PASS $round"
} problem]
set_property STEPS.WRITE_BITSTREAM.TCL.POST $hook [get_runs impl_1]
close_project
if {$status} {error $problem}
