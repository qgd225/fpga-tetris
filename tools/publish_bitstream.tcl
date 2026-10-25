# 将本工程生成的最新版比特流发布到本工程唯一的 bit 目录。
proc publish_bitstream {source project_root} {
    set source [file normalize $source]
    if {![file isfile $source] || [file size $source] == 0} {error "Missing bitstream: $source"}
    set project_root [file normalize $project_root]
    set destination [file join $project_root bit]
    file mkdir $destination
    set target [file join $destination Tetris.bit]
    if {[file isfile $target]} {
        set old_stream [open $target rb]
        set old_data [read $old_stream]
        close $old_stream
        set new_stream [open $source rb]
        set new_data [read $new_stream]
        close $new_stream
        if {$old_data eq $new_data} {puts "LATEST_BITSTREAM_UNCHANGED $target"; return}
        set digest [string trim [exec python -c {import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest()[:12])} $target]]
        set stamp [clock format [clock seconds] -format %Y%m%d_%H%M%S]
        set archive [file join $destination Tetris_${stamp}_${digest}.bit]
        if {![file exists $archive]} {file copy $target $archive}
        puts "ARCHIVED_BITSTREAM $archive"
    }
    set temporary "${target}.[pid].tmp"
    file copy -force $source $temporary
    file rename -force $temporary $target
    puts "LATEST_BITSTREAM $target"
}
