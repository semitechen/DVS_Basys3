## Basys3 XDC for Board B (UART Audio Receiver & 16x R-2R DAC Engine)

## Clock signal (100 MHz System Clock)
set_property PACKAGE_PIN W5 [get_ports clk]
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## LEDs (LED[15:0]: Heartbeat, UART Active, Watchdog Strobe, 12-LED Audio VU-Meter)
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

## Buttons (BTNC: Reset)
set_property PACKAGE_PIN U18 [get_ports rst]  
    set_property IOSTANDARD LVCMOS33 [get_ports rst]

## Pmod Header JC (High-Speed UART Audio Receiver from Board A)
## JC1 (Pin 1) - UART RX
set_property PACKAGE_PIN K17 [get_ports uart_rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]
set_property PULLUP true [get_ports uart_rx_pin]

## Pmod Header JA Lower Row (DAC Bits 0-3)
## JA7 (Dolny rząd, pin 1) - DAC Bit 3
set_property PACKAGE_PIN H1 [get_ports {dac[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[3]}]

## JA8 (Dolny rząd, pin 2) - DAC Bit 2
set_property PACKAGE_PIN K2 [get_ports {dac[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[2]}]

## JA9 (Dolny rząd, pin 3) - DAC Bit 1
set_property PACKAGE_PIN H2 [get_ports {dac[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[1]}]

## JA10 (Dolny rząd, pin 4) - DAC Bit 0
set_property PACKAGE_PIN G3 [get_ports {dac[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[0]}]

## Pmod Header JXADC (DAC Bits 4-7)
## XA3_P (DAC Bit 4)
set_property PACKAGE_PIN M2 [get_ports {dac[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[4]}]

## XA3_N (DAC Bit 5)
set_property PACKAGE_PIN M1 [get_ports {dac[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[5]}]

## XA4_P (DAC Bit 6)
set_property PACKAGE_PIN N2 [get_ports {dac[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[6]}]

## XA4_N (DAC Bit 7)
set_property PACKAGE_PIN N1 [get_ports {dac[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dac[7]}]

## Non-Volatile QSPI Flash Boot Configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
