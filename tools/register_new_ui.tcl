# Project registration; run only while this project is open for maintenance.
set ui_source [file join $root Tetris.srcs sources_1 new]
foreach pattern {ui_*.v ui_*.vh ui_*.mem reference_ui_renderer.v reference_ui_geometry.vh} {
 foreach path [glob -nocomplain [file join $ui_source $pattern]] {
  if {[llength [get_files -quiet $path]]==0} {add_files -norecurse $path}
 }
}
# No live full-frame skin; retain the historical files for standalone oracles.
foreach name {reference_ui_skin.mem reference_ui_digits.mem reference_ui_material.mem} {
 set entries [get_files -quiet [file join $ui_source $name]]
 if {[llength $entries]} {remove_files $entries}
}
set_property include_dirs [list $ui_source] [get_filesets sources_1]

set ui_cdc [file join $root Tetris.srcs constrs_1 new new_ui_cdc.xdc]
if {[llength [get_files -quiet $ui_cdc]]==0} {add_files -fileset constrs_1 -norecurse $ui_cdc}
set_property USED_IN_SYNTHESIS false [get_files $ui_cdc]
set_property USED_IN_IMPLEMENTATION true [get_files $ui_cdc]
set_property PROCESSING_ORDER LATE [get_files $ui_cdc]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
