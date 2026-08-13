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
    ../rtl/vga_pkg.sv
    rtl/clk_wiz_0.v
    rtl/clk_wiz_0_clk_wiz.v
    ../rtl/vga_if.sv
    ../rtl/vga_timing.sv
    ../rtl/font_rom.sv
    ../rtl/delay.sv
    ../rtl/char_rom.sv
    ../rtl/draw_rect_char.sv
    ../rtl/image_rom.sv
    ../rtl/draw_bg.sv
    ../rtl/draw_rect.sv
    ../rtl/draw_mouse.sv
    ../rtl/draw_rect_ctl.sv
    ../rtl/top_vga.sv
    rtl/top_vga_basys3.sv
    ../rtl/top_dvs_basys3.sv
    ../rtl/track_lut.sv
    ../rtl/spi_master.sv
    ../rtl/audio_fifo.sv
    ../rtl/sd_card_controller.sv
    ../rtl/sd_bram_bridge.sv
    ../rtl/r2r_dac.sv
    ../rtl/xadc_interface.sv

    ../rtl/timecode_filter.sv
    ../rtl/timecode_speed_detector.sv
    ../rtl/timecode_direction_detector.sv

}


# Specify Verilog design files location         -- EDIT
# set verilog_files {
#     path/to/file.v
# }

# Specify VHDL design files location            -- EDIT
set vhdl_files {
    ../rtl/Ps2Interface.vhd
    ../rtl/MouseCtl.vhd
    ../rtl/MouseDisplay.vhd
}

# Specify files for a memory initialization     -- EDIT
 set mem_files {
    ../rtl/image_rom.data
 }
