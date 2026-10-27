# 工程策略只读取 docs/AGENTS.md；根目录文件只提供导航。
proc project_rules_file {root} {
    set path [file join $root docs AGENTS.md]
    if {![file isfile $path]} {error "Missing canonical rules file: $path"}
    return $path
}

proc project_timing_limits {root} {
    set stream [open [project_rules_file $root] r]
    fconfigure $stream -encoding utf-8
    set text [read $stream]
    close $stream
    set limits [dict create]
    foreach key {TIMING_MIN_WNS_NS TIMING_MIN_WHS_NS TIMING_MAX_TNS_NS TIMING_MAX_THS_NS} {
        if {![regexp [format {%s=([0-9.]+)} $key] $text -> value]} {error "Missing timing setting: $key"}
        dict set limits $key $value
    }
    return $limits
}

proc verify_project_timing {root} {
    set limits [project_timing_limits $root]
    set summary [report_timing_summary -return_string]
    if {![regexp {(?s)WNS\(ns\).*?\n\s*-+[^\n]*\n\s*([-+0-9.]+)\s+([-+0-9.]+)\s+[0-9]+\s+[0-9]+\s+([-+0-9.]+)\s+([-+0-9.]+)} $summary -> wns tns whs ths]} {
        error "Cannot parse routed timing summary"
    }
    if {$wns < [dict get $limits TIMING_MIN_WNS_NS] || $whs < [dict get $limits TIMING_MIN_WHS_NS] || $tns != [dict get $limits TIMING_MAX_TNS_NS] || $ths != [dict get $limits TIMING_MAX_THS_NS]} {
        error "Timing policy failed: WNS=$wns WHS=$whs TNS=$tns THS=$ths"
    }
    return [dict create WNS $wns WHS $whs TNS $tns THS $ths]
}
