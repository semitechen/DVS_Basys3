## This file is a general .xdc for the Basys3 rev B board
## Configured for Integrated DVS Audio System (XADC Timecode + SD Audio Player + 8-bit DAC)

## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN V3 [get_ports {led[9]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN W3 [get_ports {led[10]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN U3 [get_ports {led[11]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN P3 [get_ports {led[12]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN N3 [get_ports {led[13]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN P1 [get_ports {led[14]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN L1 [get_ports {led[15]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

## Buttons
set_property PACKAGE_PIN U18 [get_ports rst]  
    set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN T18 [get_ports btn_up]
    set_property IOSTANDARD LVCMOS33 [get_ports btn_up]
set_property PACKAGE_PIN U17 [get_ports btn_down]
    set_property IOSTANDARD LVCMOS33 [get_ports btn_down]

## Pmod Header JA (Karta SD + DAC bity 0-3)
## Sch name = JA1 (Górny rząd, pin 1) - SD CS
set_property PACKAGE_PIN J1 [get_ports {sd_cs}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_cs}]

## Sch name = JA2 (Górny rząd, pin 2) - SD MISO
set_property PACKAGE_PIN L2 [get_ports {sd_miso}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_miso}]
set_property PULLUP true [get_ports {sd_miso}]

## Sch name = JA3 (Górny rząd, pin 3) - SD MOSI
set_property PACKAGE_PIN J2 [get_ports {sd_mosi}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_mosi}]

## Sch name = JA4 (Górny rząd, pin 4) - SD SCK
set_property PACKAGE_PIN G2 [get_ports {sd_sck}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_sck}]

## Sch name = JA7 (Dolny rząd, pin 1) - DAC Bit 3
set_property PACKAGE_PIN H1 [get_ports {dac[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[3]}]

## Sch name = JA8 (Dolny rząd, pin 2) - DAC Bit 2
set_property PACKAGE_PIN K2 [get_ports {dac[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[2]}]

## Sch name = JA9 (Dolny rząd, pin 3) - DAC Bit 1
set_property PACKAGE_PIN H2 [get_ports {dac[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[1]}]

## Sch name = JA10 (Dolny rząd, pin 4) - DAC Bit 0
set_property PACKAGE_PIN G3 [get_ports {dac[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[0]}]

## Pmod Header JC (UART RX Optional)
set_property PACKAGE_PIN K17 [get_ports uart_rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]
set_property PULLUP true [get_ports uart_rx_pin]

## Pmod Header JXADC (XADC Analog Timecode Inputs + DAC bity 4-7)
## Sch name = XA1_P (Left Channel Analog In +)
set_property PACKAGE_PIN J3 [get_ports vauxp6]
    set_property IOSTANDARD LVCMOS33 [get_ports vauxp6]

## Sch name = XA1_N (Left Channel Analog In -)
set_property PACKAGE_PIN K3 [get_ports vauxn6]
    set_property IOSTANDARD LVCMOS33 [get_ports vauxn6]

## Sch name = XA2_P (Right Channel Analog In +)
set_property PACKAGE_PIN L3 [get_ports vauxp14]
	set_property IOSTANDARD LVCMOS33 [get_ports vauxp14]

## Sch name = XA2_N (Right Channel Analog In -)
set_property PACKAGE_PIN M3 [get_ports vauxn14]
	set_property IOSTANDARD LVCMOS33 [get_ports vauxn14]

## Sch name = XA3_P (DAC Bit 4)
set_property PACKAGE_PIN M2 [get_ports {dac[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[4]}]

## Sch name = XA3_N (DAC Bit 5)
set_property PACKAGE_PIN M1 [get_ports {dac[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[5]}]

## Sch name = XA4_P (DAC Bit 6)
set_property PACKAGE_PIN N2 [get_ports {dac[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[6]}]

## Sch name = XA4_N (DAC Bit 7)
set_property PACKAGE_PIN N1 [get_ports {dac[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[7]}]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
