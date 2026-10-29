# Implementation-only late XDC. No synchronous path is excluded.
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ net_screen_tx_inst/packets/wg_reg*}] -to [get_cells -hier -filter {NAME =~ net_screen_tx_inst/packets/wg1_reg*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ net_screen_tx_inst/packets/rg_reg*}] -to [get_cells -hier -filter {NAME =~ net_screen_tx_inst/packets/rg1_reg*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ net_screen_tx_inst/eth_udp_loopback_rgmii_inst/word_transmit.words/wg_reg*}] -to [get_cells -hier -filter {NAME =~ net_screen_tx_inst/eth_udp_loopback_rgmii_inst/word_transmit.words/wg1_reg*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ net_screen_tx_inst/eth_udp_loopback_rgmii_inst/word_transmit.words/rg_reg*}] -to [get_cells -hier -filter {NAME =~ net_screen_tx_inst/eth_udp_loopback_rgmii_inst/word_transmit.words/rg1_reg*}]
