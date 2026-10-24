# Publish the latest bitstream to the shared local release directory.
proc publish_bitstream {source project_root} {
    set source [file normalize $source]
    if {![file isfile $source] || [file size $source] == 0} {error "Missing bitstream: $source"}
    set project_root [file normalize $project_root]
    set central [file join [file dirname $project_root] Tetris]
    if {![file isfile [file join $central Tetris.xpr]]} {set central $project_root}
    set destination [file join $central bit]
    file mkdir $destination
    set target [file join $destination Tetris.bit]
    set temporary "${target}.[pid].tmp"
    file copy -force $source $temporary
    file rename -force $temporary $target
    puts "LATEST_BITSTREAM $target"
}
