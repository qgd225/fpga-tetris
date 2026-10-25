set root [file dirname [file normalize [info script]]]
cd $root
create_project -in_memory -part xc7a35tfgg484-2
read_verilog hud_font_rom.v
read_verilog hud_text.v
synth_design -top hud_text -mode out_of_context
report_utilization -hierarchical -file utilization.rpt
close_project
