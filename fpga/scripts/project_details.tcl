# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# sv_files and vhdl_files should contain all files required for synthesis.

#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name dvs_system

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
    ../rtl/top_sd_test.sv
    ../rtl/top_dvs_basys3.sv
    ../rtl/track_lut.sv
    ../rtl/spi_master.sv
    ../rtl/audio_fifo.sv
    ../rtl/sd_card_controller.sv
    ../rtl/sd_bram_bridge.sv
    ../rtl/dac_player.sv
    
    ../rtl/xadc_interface.sv
    ../rtl/ds_dac.sv
    ../rtl/timecode_filter.sv
    ../rtl/timecode_speed_detector.sv
    ../rtl/timecode_direction_detector.sv
}

# Specify Verilog design files location         -- EDIT
# set verilog_files {
#     path/to/file.v
# }

# Specify VHDL design files location            -- EDIT
#set vhdl_files {
#}

# Specify files for a memory initialization     -- EDIT
 #set mem_files {
 # 
 #}
