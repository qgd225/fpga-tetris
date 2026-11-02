# Called only after the owning build has passed hardware/source validation.
# Conversion and paired archival are shared with the Python release entry.
proc publish_bitstream {source project_root} {
    set source [file normalize $source]
    set project_root [file normalize $project_root]
    puts [exec python [file join $project_root tools publish_bitstream.py] $source --root $project_root]
}
