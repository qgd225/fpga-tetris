# Vivado write_bitstream post hook; only a complete generated bitstream is published.
set publication_root [file normalize [file join [file dirname [info script]] ..]]
source [file join $publication_root tools publish_bitstream.tcl]
source [file join $publication_root tools project_policy.tcl]
verify_project_timing $publication_root
# write_bitstream 后置钩子运行在实现目录；不要再次拼接相对的 run DIRECTORY。
# 实现目录只应含本次顶层生成的一个 bit；显式检查，避免误选其他版本。
set publication_candidates [glob -nocomplain -directory [pwd] *.bit]
if {[llength $publication_candidates] != 1} {error "Expected exactly one generated bitstream in [pwd]"}
set publication_source [lindex $publication_candidates 0]
publish_bitstream $publication_source $publication_root
