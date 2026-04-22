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
        input  logic clk100MHz,
        inout  wire  ps2_clk,
        inout  wire  ps2_data,
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
/**
 * Local variables and signals
 */

logic [11:0] x_pos, y_pos;

vga_if vga_bg();    
vga_if vga_rect();  
vga_if vga_out();

...

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

MouseCtl u_MouseCtl (
    .clk         (clk100MHz),
    .rst         (!rst_n),
    .xpos        (x_pos),
    .ypos        (y_pos),
    .zpos        (),
    .left        (),
    .middle      (),
    .right       (),
    .new_event   (),
    .value       (12'b0),
    .setx        (1'b0),
    .sety        (1'b0),
    .setmax_x    (1'b0),
    .setmax_y    (1'b0),
    .ps2_clk     (ps2_clk),
    .ps2_data    (ps2_data)
);

draw_bg u_draw_bg (
    .clk,
    .rst_n,
    .vga_in  (vga_bg),
    .vga_out (vga_rect)
);

draw_rect #(
    .WIDTH(640),
    .HEIGHT(240),
    .THICKNESS(5),
    .COLOR(12'hf_0_0) 
) u_draw_rect (
    .clk     (clk),
    .rst_n   (rst_n),
    .x_pos   (x_pos),
    .y_pos   (y_pos),
    .vga_in  (vga_rect),
    .vga_out (vga_out)
);

endmodule
