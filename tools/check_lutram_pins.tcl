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

# Prove only combinational equivalence. Registers, memories and input ports
# remain distinct state/input leaves; no register is merged by its name.
proc lutram_logic_output {driver} {
    global lutram_equiv_output lutram_equiv_expr lutram_equiv_sources lutram_equiv_next lutram_equiv_busy
    if {[dict exists $lutram_equiv_output $driver]} {return [dict get $lutram_equiv_output $driver]}
    if {[dict exists $lutram_equiv_busy $driver]} {error "Combinational cycle in LUTRAM driver proof: $driver"}
    dict set lutram_equiv_busy $driver 1
    set result "PIN:$driver"
    set cell [get_cells -quiet -of_objects $driver]
    if {[llength $cell]==1} {
        set ref [get_property REF_NAME $cell]
        if {$ref eq "GND"} {set result CONST0}
        if {$ref eq "VCC"} {set result CONST1}
        if {[regexp {^LUT[1-6](_2)?$} $ref]} {
            set init [get_property INIT $cell]
            set expression [list $ref [get_property REF_PIN_NAME $driver] $init]
            set values [dict create]
            foreach input [lsort [get_pins -of_objects $cell -filter {DIRECTION == IN}]] {
                set name [get_property REF_PIN_NAME $input]
                set value [lutram_logic_driver $input]
                dict set values $name $value
                lappend expression $name $value
            }
            if {$ref eq "LUT1" && $init eq "2'h2" && [llength [dict get $values I0]]==1} {
                # A physical hold/fanout buffer with truth table 0->0,1->1.
                set result [lindex [dict get $values I0] 0]
            } else {
                if {![dict exists $lutram_equiv_expr $expression]} {
                    dict set lutram_equiv_expr $expression "LUT_EQ_[incr lutram_equiv_next]"
                }
                set result [dict get $lutram_equiv_expr $expression]
            }
        }
    }
    dict unset lutram_equiv_busy $driver
    dict set lutram_equiv_output $driver $result
    dict lappend lutram_equiv_sources $result $driver
    return $result
}
proc lutram_logic_driver {pin} {
    set drivers [lutram_driver $pin]
    if {[llength $drivers]==0} {return "UNDRIVEN:$pin"}
    set result {}
    foreach driver $drivers {lappend result [lutram_logic_output $driver]}
    return [lsort -unique $result]
}

proc check_lutram_pins {report_path} {
    global lutram_driver_cache
    set lutram_driver_cache [dict create]
    global lutram_equiv_output lutram_equiv_expr lutram_equiv_sources lutram_equiv_next lutram_equiv_busy
    set lutram_equiv_output [dict create];set lutram_equiv_expr [dict create]
    set lutram_equiv_sources [dict create];set lutram_equiv_busy [dict create];set lutram_equiv_next 0
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
            set driver [lutram_logic_driver $pin]
            if {$driver ne [lutram_logic_driver $parent_pin]} {error "Wrong $pin_name connection on $name"}
            if {$pin_name in {A0 A1 A2 A3 A4 WE WCLK}} {
                if {[dict exists $expected $pin_name] && [dict get $expected $pin_name] ne $driver} {
                    error "Replicas disagree on $pin_name at $name"
                }
                dict set expected $pin_name $driver
            }
        }
        set d [get_pins -of_objects $memory -filter {REF_PIN_NAME == D}]
        set data_pin [dict get $parents $parent "write_data\[$bit_index\]"]
        if {[llength $data_pin] != 1 || [lutram_logic_driver $d] ne [lutram_logic_driver $data_pin]} {
            error "Wrong data bit on $name"
        }
        puts $output "$name OK"
    }
    dict for {pin driver} $expected {puts $output "$pin: $driver"}
    puts $output "PASS: 768 RAM bits; independent read addresses; common write address/data/enable/clock."
    close $output
    puts "LUTRAM_PIN_CHECK_PASS [llength $memories]"
    check_metadata_pins "[file rootname $report_path]_metadata.rpt"
    set proof [open "[file rootname $report_path]_logic_equivalence.rpt" w]
    puts $proof "Only LUT truth tables with recursively identical input functions, constants and LUT1 identity buffers are normalized. Every sequential/memory/input leaf retains its exact identity."
    dict for {expression id} $lutram_equiv_expr {
        set sources [lsort -unique [dict get $lutram_equiv_sources $id]]
        if {[llength $sources]>1} {puts $proof "$id SOURCES=$sources EXPRESSION=$expression"}
    }
    close $proof
}

proc check_metadata_pins {report_path} {
    set memories [get_cells -hierarchical -filter {REF_NAME == RAM32X1D && NAME =~ *metadata_banks*}]
    set count [llength $memories]
    if {$count==0} {return}
    # The new renderer consumes all three type bits; its unused owner output
    # may be removed globally. Do not allow partial banks or a missing type bit.
    if {$count ni {144 192}} {error "Expected 144 type bits or 192 type+owner metadata bits, found $count"}
    set width [expr {$count/48}]
    set output [open $report_path w]
    set parents [dict create]
    set seen [dict create]
    set parent_cells [dict create]
    foreach c [get_cells -hierarchical -filter {REF_NAME =~ cell_metadata_bank*}] {dict set parent_cells [get_property NAME $c] $c}
    foreach memory $memories {
        set name [get_property NAME $memory]
        if {![regexp {^(.*)/bits\[([0-9]+)\][.](display|copy)_ram$} $name -> parent bit_index kind]} {error "Unexpected metadata RAM name: $name"}
        if {$bit_index >= $width} {error "Unexpected live metadata bit $name"}
        if {![dict exists $parents $parent]} {
            set pins [dict create]
            foreach pin [get_pins -of_objects [dict get $parent_cells $parent]] {dict set pins [get_property REF_PIN_NAME $pin] $pin}
            # Vivado rebuilt hierarchy aliases these three input families.
            dict for {ref pin} $pins {
                if {[regexp {^meta_write_addr(\[[0-9]+\])$} $ref -> suffix]} {dict set pins write_addr$suffix $pin}
                if {[string match *.we $ref]} {dict set pins we $pin}
                if {$ref eq "clk_out1"} {dict set pins clk $pin}
            }
            dict set parents $parent $pins
        }
        if {[dict exists $seen $parent $kind $bit_index]} {error "Duplicate metadata bit $name"}
        dict set seen $parent $kind $bit_index 1
        set read_port [expr {$kind eq "display"?"display_row":"copy_row"}]
        set port_map [dict create A0 {write_addr[0]} A1 {write_addr[1]} A2 {write_addr[2]} A3 {write_addr[3]} A4 {write_addr[4]} WE we WCLK clk]
        for {set bit 0} {$bit<5} {incr bit} {dict set port_map DPRA$bit "${read_port}\[$bit\]"}
        dict set port_map D "write_data\[$bit_index\]"
        dict for {pin_name port_name} $port_map {
            if {![dict exists $parents $parent $port_name]} {error "Missing metadata hierarchy port $parent/$port_name"}
            set leaf [get_pins -of_objects $memory -filter "REF_PIN_NAME == $pin_name"]
            if {[lutram_logic_driver $leaf] ne [lutram_logic_driver [dict get $parents $parent $port_name]]} {error "Wrong metadata $pin_name on $name"}
        }
        puts $output "$name OK"
    }
    if {[dict size $parents]!=24} {error "Expected 24 complete metadata column banks"}
    dict for {parent pins} $parents {
        foreach kind {display copy} {
            for {set bit 0} {$bit<$width} {incr bit} {
                if {![dict exists $seen $parent $kind $bit]} {error "Missing metadata bit $parent/$kind/$bit"}
            }
        }
    }
    puts $output "PASS: $count metadata bits, 24 complete columns, two independent read ports, all live data/address/enable/clock pins checked; unused owner may be pruned."
    close $output
    puts "METADATA_PIN_CHECK_PASS $count LIVE_BITS_PER_BANK=$width"
}
