/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * The project top module.
 */

module top_vga (
        input  logic clk,
        input  logic rst_n,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */


    vga_if vga_bg();    
    vga_if vga_rect();  
    vga_if vga_out();

    assign vga_bg.rgb = 12'h0_0_0;

    /**
     * Signals assignments
     */

    assign vs = vga_out.vsync;
    assign hs = vga_out.hsync;
    assign {r,g,b} = vga_out.rgb;


    /**
     * Submodules instances
     */

    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vcount (vga_bg.vcount),
        .vsync  (vga_bg.vsync),
        .vblnk  (vga_bg.vblnk),
        .hcount (vga_bg.hcount),
        .hsync  (vga_bg.hsync),
        .hblnk  (vga_bg.hblnk)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .vga_in  (vga_bg),
        .vga_out (vga_rect)
    );

    draw_rect #(
        .x_pos(80),
        .y_pos(180),
        .WIDTH(640),
        .HEIGHT(240),
        .THICKNESS(5),
        .COLOR(12'hf_0_0) 
    ) u_draw_rect (
        .clk     (clk),
        .rst_n   (rst_n),
        .vga_in  (vga_rect),
        .vga_out (vga_out)
    );


endmodule
