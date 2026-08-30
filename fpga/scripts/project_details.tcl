# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project details required for generate_bitstream.tcl
# Konfiguracja dla Płytki B (Odtwarzacz Audio)

#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name dvs_board_b_player

# Top module name                               -- EDIT
set top_module top_board_b_player

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
    ../rtl/top_board_b_player.sv
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
#set vhdl_files {
#}

# Specify files for a memory initialization     -- EDIT
 #set mem_files {
 # 
 #}