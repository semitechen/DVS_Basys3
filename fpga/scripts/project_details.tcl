# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project details required for generate_bitstream.tcl
# Integrated DVS System (XADC Timecode + SD Audio Player + 16x DAC)

#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name dvs_basys3_integrated


# Top module name                               -- EDIT
set top_module top_dvs_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
    constraints/top_dvs_basys3.xdc
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
    ../rtl/top_dvs_basys3.sv
    ../rtl/xadc_interface.sv
    ../rtl/timecode_pos_tracker.sv
    ../rtl/led_pos_display.sv
    
    ../rtl/r2r_dac.sv
    ../rtl/track_selector.sv
    ../rtl/track_lut.sv
    ../rtl/spi_master.sv
    ../rtl/audio_fifo.sv
    ../rtl/sd_card_controller.sv
    ../rtl/sd_bram_bridge.sv
    ../rtl/variable_speed_player.sv
    ../rtl/button_debouncer.sv
    
    ../rtl/dvs_uart_receiver.sv
    ../rtl/uart_rx.sv
}

# Specify Verilog design files location         -- EDIT
# set verilog_files {
# }

# Specify VHDL design files location            -- EDIT
set vhdl_files {
    ../rtl/Ps2Interface.vhd
    ../rtl/MouseCtl.vhd
    ../rtl/MouseDisplay.vhd
}

# Specify files for a memory initialization     -- EDIT
# set mem_files {
# }
