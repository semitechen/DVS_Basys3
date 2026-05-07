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
     wire mouse_left_click;
     wire [11:0] phys_x_pos;
    wire [11:0] phys_y_pos;

    vga_if vga_bg();    
    vga_if vga_char();
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
        .left        (mouse_left_click),
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
        .vga_out (vga_char)
    );

    logic [10:0] char_addr;
    logic [7:0] char_pixels;

    font_rom u_font_rom (
        .clk,
        .addr (char_addr),
        .char_line_pixels (char_pixels)
    );

    draw_rect_char u_draw_rect_char (
        .clk,
        .rst_n,
        .char_line_pixels (char_pixels),
        .addr (char_addr),
        .vga_in (vga_char),
        .vga_out (vga_rect)
    );

    image_rom u_image_rom (
        .clk     (clk),
        .address (pixel_addr),
        .rgb     (rom_rgb)    
    );

    draw_rect #(
        .WIDTH(48),
        .HEIGHT(64),
        .THICKNESS(0),
        .COLOR(12'hf_0_0) 
    ) u_draw_rect (
        .clk     (clk),
        .rst_n   (rst_n),
        .x_pos   (phys_x_pos),
        .y_pos   (phys_y_pos),
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

    draw_rect_ctl u_draw_rect_ctl (
    .clk        (clk),              
    .rst_n      (rst_n),
    .mouse_left (mouse_left_click),  
    .mouse_xpos (x_pos_sync),        
    .mouse_ypos (y_pos_sync),        
    .xpos       (phys_x_pos),        
    .ypos       (phys_y_pos)       
);


endmodule
