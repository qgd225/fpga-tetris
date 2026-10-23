# Compare leaf drivers through hierarchy, not display names of local net segments.
proc lutram_driver {pin} {
    global lutram_driver_cache
    set local_key [get_nets -quiet -of_objects $pin]
    if {[dict exists $lutram_driver_cache $local_key]} {return [dict get $lutram_driver_cache $local_key]}
    set nets [get_nets -quiet -segments -of_objects $pin]
    set key [lsort $nets]
    if {[dict exists $lutram_driver_cache $key]} {
        set result [dict get $lutram_driver_cache $key]
        dict set lutram_driver_cache $local_key $result
        return $result
    }
    set drivers [get_pins -quiet -leaf -of_objects $nets -filter {DIRECTION == OUT}]
    set ports [get_ports -quiet -of_objects $nets -filter {DIRECTION == IN}]
    set result [lsort -unique [concat $drivers $ports]]
    dict set lutram_driver_cache $key $result
    dict set lutram_driver_cache $local_key $result
    return $result
}

proc check_lutram_pins {report_path} {
    global lutram_driver_cache
    set lutram_driver_cache [dict create]
    set memories [get_cells -hierarchical -filter {REF_NAME == RAM32X1D && NAME =~ *board_reads*}]
    if {[llength $memories] != 768} {error "Expected 768 RAM32X1D bits, found [llength $memories]"}
    set output [open $report_path w]
    set expected [dict create]
    set parents [dict create]
    set port_map [dict create A0 {write_addr[0]} A1 {write_addr[1]} A2 {write_addr[2]} \
        A3 {write_addr[3]} A4 {write_addr[4]} WE we WCLK clk \
        DPRA0 {read_addr[0]} DPRA1 {read_addr[1]} DPRA2 {read_addr[2]} \
        DPRA3 {read_addr[3]} DPRA4 {read_addr[4]}]
    foreach memory $memories {
        set name [get_property NAME $memory]
        if {![regexp {^(.*)/bits\[([0-9]+)\][.]ram$} $name -> parent bit_index]} {
            close $output
            error "Unexpected RAM instance name: $name"
        }
        if {![dict exists $parents $parent]} {
            set parent_cell [get_cells -hierarchical -filter "NAME == $parent"]
            set pins [dict create]
            foreach pin [get_pins -of_objects $parent_cell] {
                dict set pins [get_property REF_PIN_NAME $pin] $pin
            }
            dict set parents $parent $pins
        }
        dict for {pin_name port_name} $port_map {
            set pin [get_pins -of_objects $memory -filter "REF_PIN_NAME == $pin_name"]
            if {![dict exists $parents $parent $port_name]} {error "Missing hierarchy pin $parent/$port_name"}
            set parent_pin [dict get $parents $parent $port_name]
            set driver [lutram_driver $pin]
            if {$driver ne [lutram_driver $parent_pin]} {error "Wrong $pin_name connection on $name"}
            if {$pin_name in {A0 A1 A2 A3 A4 WE WCLK}} {
                if {[dict exists $expected $pin_name] && [dict get $expected $pin_name] ne $driver} {
                    error "Replicas disagree on $pin_name at $name"
                }
                dict set expected $pin_name $driver
            }
        }
        set d [get_pins -of_objects $memory -filter {REF_PIN_NAME == D}]
        set data_pin [dict get $parents $parent "write_data\[$bit_index\]"]
        if {[llength $data_pin] != 1 || [lutram_driver $d] ne [lutram_driver $data_pin]} {
            error "Wrong data bit on $name"
        }
        puts $output "$name OK"
    }
    dict for {pin driver} $expected {puts $output "$pin: $driver"}
    puts $output "PASS: 768 RAM bits; independent read addresses; common write address/data/enable/clock."
    close $output
    puts "LUTRAM_PIN_CHECK_PASS [llength $memories]"
}
