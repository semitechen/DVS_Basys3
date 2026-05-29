/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller.
 */

module vga_timing (
        input  logic clk,
        input  logic rst,
        output logic [10:0] vcount,
        output logic vsync,
        output logic vblnk,
        output logic [10:0] hcount,
        output logic hsync,
        output logic hblnk
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */

    // Add your signals and variables here.


    /**
     * Internal logic
     */

    // Add your code here.


endmodule
