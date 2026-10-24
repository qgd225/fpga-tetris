# 独立组合 mapper 初筛；不打开工程、不实现整机、不发布 bit。
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root docs reports story_r2a_mapper]
file mkdir $output
foreach kind {0 1} {
    create_project -in_memory -part xc7a35tfgg484-2
    read_verilog [file join $root Tetris.srcs sources_1 new Playfield_pixel_mapper.v]
    read_verilog [file join $root Tetris.srcs sources_1 new story_pixel_mapper.v]
    read_verilog [file join $root sim story_layout mapper_measure.v]
    synth_design -top mapper_measure -mode out_of_context -generic USE_STORY=$kind
    report_utilization -file [file join $output mapper_${kind}.rpt]
    close_project
}
puts "MAPPER_MEASUREMENT_COMPLETE"
