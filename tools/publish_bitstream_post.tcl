# Vivado write_bitstream post hook; only a complete generated bitstream is published.
set publication_root [file normalize [file join [file dirname [info script]] ..]]
source [file join $publication_root tools publish_bitstream.tcl]
set publication_source [file join [get_property DIRECTORY [current_run -implementation]] "[get_property TOP [get_filesets sources_1]].bit"]
publish_bitstream $publication_source $publication_root
