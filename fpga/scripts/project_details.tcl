# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
<<<<<<< HEAD
set project_name dvs_system
=======
set project_name vga_project
>>>>>>> classroom/main

# Top module name                               -- EDIT
set top_module top_dvs_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
<<<<<<< HEAD
    constraints/top_dvs_basys3.xdc
    
=======
    constraints/top_vga_basys3.xdc
>>>>>>> classroom/main
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
<<<<<<< HEAD
    ../rtl/top_dvs_basys3.sv
    ../rtl/track_lut.sv
    ../rtl/xadc_interface.sv
=======
    ../rtl/vga_pkg.sv
    ../rtl/vga_timing.sv
    ../rtl/draw_bg.sv
    ../rtl/top_vga.sv
    rtl/top_vga_basys3.sv
>>>>>>> classroom/main
}

# Specify Verilog design files location         -- EDIT
# set verilog_files {
#     path/to/file.v
# }

# Specify VHDL design files location            -- EDIT
<<<<<<< HEAD
#set vhdl_files {
#}

# Specify files for a memory initialization     -- EDIT
 #set mem_files {   
 #}
=======
# set vhdl_files {
#    path/to/file.vhd
# }

# Specify files for a memory initialization     -- EDIT
# set mem_files {
#    path/to/file.data
# }
>>>>>>> classroom/main
