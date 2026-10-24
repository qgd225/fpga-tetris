# 将本工程生成的最新版比特流发布到本工程唯一的 bit 目录。
proc publish_bitstream {source project_root} {
    set source [file normalize $source]
    if {![file isfile $source] || [file size $source] == 0} {error "Missing bitstream: $source"}
    set project_root [file normalize $project_root]
    set destination [file join $project_root bit]
    file mkdir $destination
    set target [file join $destination Tetris.bit]
    set temporary "${target}.[pid].tmp"
    file copy -force $source $temporary
    file rename -force $temporary $target
    puts "LATEST_BITSTREAM $target"
}
