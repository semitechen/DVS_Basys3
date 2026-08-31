## Basys3 XDC for Board A (Timecode Acquisition & SD Audio Streamer)

## Clock signal (100 MHz System Clock)
set_property PACKAGE_PIN W5 [get_ports clk]
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches (SW0: 1 = DVS Mode, 0 = Standalone Auto-Play)
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]

## LEDs (LED[15:0]: Heartbeat, Direction, Squelch Signal Present, Vinyl Platter Tracker)
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

## Buttons (BTNC: Reset, BTNU: Track Next, BTND: Track Prev)
set_property PACKAGE_PIN U18 [get_ports rst]  
    set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN T18 [get_ports btn_up]
    set_property IOSTANDARD LVCMOS33 [get_ports btn_up]
set_property PACKAGE_PIN U17 [get_ports btn_down]
    set_property IOSTANDARD LVCMOS33 [get_ports btn_down]

## Pmod Header JA (Micro-SD Card SPI Interface)
## JA1 (CS)
set_property PACKAGE_PIN J1 [get_ports {sd_cs}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_cs}]

## JA2 (MISO)
set_property PACKAGE_PIN L2 [get_ports {sd_miso}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_miso}]
set_property PULLUP true [get_ports {sd_miso}]

## JA3 (MOSI)
set_property PACKAGE_PIN J2 [get_ports {sd_mosi}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_mosi}]

## JA4 (SCK)
set_property PACKAGE_PIN G2 [get_ports {sd_sck}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_sck}]

## Pmod Header JC (High-Speed UART Audio Transmitter to Board B)
## JC1 (Pin 1) - UART TX
set_property PACKAGE_PIN K17 [get_ports uart_tx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_pin]

## Pmod Header JXADC (Analog Timecode Inputs from Turntable)
## XA1_P (Left Channel Analog In +)
set_property PACKAGE_PIN J3 [get_ports vauxp6]
    set_property IOSTANDARD LVCMOS33 [get_ports vauxp6]

## XA1_N (Left Channel Analog In -)
set_property PACKAGE_PIN K3 [get_ports vauxn6]
    set_property IOSTANDARD LVCMOS33 [get_ports vauxn6]

## XA2_P (Right Channel Analog In +)
set_property PACKAGE_PIN L3 [get_ports vauxp14]
	set_property IOSTANDARD LVCMOS33 [get_ports vauxp14]

## XA2_N (Right Channel Analog In -)
set_property PACKAGE_PIN M3 [get_ports vauxn14]
	set_property IOSTANDARD LVCMOS33 [get_ports vauxn14]

## Non-Volatile QSPI Flash Boot Configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
