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

     logic [11:0] x_pos, y_pos; 
     logic [11:0] x_pos_meta, y_pos_meta;
     logic [11:0] x_pos_sync, y_pos_sync; 
     wire [11:0] pixel_addr;
     wire [11:0] rom_rgb;

    vga_if vga_bg();    
    vga_if vga_rect();  
    vga_if vga_mouse();
    vga_if vga_out();


    /**
     * Signals assignments
     */

    assign vga_bg.rgb = 12'h0_0_0;
    assign vs = vga_out.vsync;
    assign hs = vga_out.hsync;
    assign {r,g,b} = vga_out.rgb;


    /**
     * Submodules instances
     */

     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_pos_meta <= 12'b0;
            y_pos_meta <= 12'b0;
            x_pos_sync <= 12'b0;
            y_pos_sync <= 12'b0;
        end else begin
            x_pos_meta <= x_pos;
            y_pos_meta <= y_pos;
    
            x_pos_sync <= x_pos_meta;
            y_pos_sync <= y_pos_meta;
        end
    end

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

    image_rom u_image_rom (
        .clk     (clk),
        .address (pixel_addr),
        .rgb     (rom_rgb)    
    );

    draw_rect #(
        .WIDTH(640),
        .HEIGHT(240),
        .THICKNESS(5),
        .COLOR(12'hf_0_0) 
    ) u_draw_rect (
        .clk     (clk),
        .rst_n   (rst_n),
        .x_pos   (x_pos_sync),
        .y_pos   (y_pos_sync),
        .pixel_addr (pixel_addr),
        .rgb_pixel  (rom_rgb),
        .vga_in  (vga_rect),
        .vga_out (vga_mouse)
    );

    draw_mouse u_draw_mouse (
        .clk     (clk),
        .rst_n   (rst_n),
        .x_pos   (x_pos_sync),
        .y_pos   (y_pos_sync),
        .vga_in  (vga_mouse),
        .vga_out (vga_out)
    );


endmodule
