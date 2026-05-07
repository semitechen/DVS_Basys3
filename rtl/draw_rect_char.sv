/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw character rectangle with fixed BRAM timing and DRC warnings.
 */

`timescale 1ns / 1ps

module draw_rect_char #(
    parameter int X_POS = 0,
    parameter int Y_POS = 0
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] char_line_pixels,
    output logic [7:0] char_xy,
    output logic [3:0] char_line,
    vga_if.in  vga_in,
    vga_if.out vga_out
);

    import vga_pkg::*;

    // Pipeline stages for VGA signals (3 cycles total)
    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2, hcount_d3, vcount_d3;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic hsync_d3, vsync_d3, hblnk_d3, vblnk_d3;
    logic [11:0] rgb_d1, rgb_d2, rgb_d3;

    logic pixel;
    logic is_rect_nxt, is_rect_d1, is_rect_d2, is_rect_d3;
    logic [3:0] char_line_nxt, char_line_d1;
    logic [7:0] char_xy_nxt;

    logic [10:0] h_offset, v_offset;

    /**
     * T0: Address Calculation & Registration (to fix DRC async reset warning)
     */
    assign h_offset = vga_in.hcount - X_POS[10:0];
    assign v_offset = vga_in.vcount - Y_POS[10:0];

    assign char_xy_nxt   = { v_offset[6:4], h_offset[7:3] };
    assign char_line_nxt = v_offset[3:0];
    assign is_rect_nxt   = (vga_in.hcount >= X_POS) && (vga_in.hcount < X_POS + 256) && 
                           (vga_in.vcount >= Y_POS) && (vga_in.vcount < Y_POS + 128);

    always_ff @(posedge clk) begin
        char_xy      <= char_xy_nxt;
        char_line_d1 <= char_line_nxt; // Delayed once for font_rom alignment
        is_rect_d1   <= is_rect_nxt;
    end

    // char_line must be delayed 1 more cycle to match the output of char_rom
    always_ff @(posedge clk) begin
        char_line <= char_line_d1;
    end


    /**
     * VGA Signal Delay Pipeline (3 Cycles)
     */

    // Stage 1
    delay #(.WIDTH(11), .CLK_DEL(1)) u_delay_hcount_1 (.clk, .rst_n, .din(vga_in.hcount), .dout(hcount_d1));
    delay #(.WIDTH(11), .CLK_DEL(1)) u_delay_vcount_1 (.clk, .rst_n, .din(vga_in.vcount), .dout(vcount_d1));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_hsync_1  (.clk, .rst_n, .din(vga_in.hsync),  .dout(hsync_d1));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_vsync_1  (.clk, .rst_n, .din(vga_in.vsync),  .dout(vsync_d1));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_hblnk_1  (.clk, .rst_n, .din(vga_in.hblnk),  .dout(hblnk_d1));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_vblnk_1  (.clk, .rst_n, .din(vga_in.vblnk),  .dout(vblnk_d1));
    delay #(.WIDTH(12), .CLK_DEL(1)) u_delay_rgb_1    (.clk, .rst_n, .din(vga_in.rgb),    .dout(rgb_d1));

    // Stage 2
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_is_rect_2(.clk, .rst_n, .din(is_rect_d1),   .dout(is_rect_d2));
    delay #(.WIDTH(11), .CLK_DEL(1)) u_delay_hcount_2 (.clk, .rst_n, .din(hcount_d1), .dout(hcount_d2));
    delay #(.WIDTH(11), .CLK_DEL(1)) u_delay_vcount_2 (.clk, .rst_n, .din(vcount_d1), .dout(vcount_d2));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_hsync_2  (.clk, .rst_n, .din(hsync_d1),  .dout(hsync_d2));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_vsync_2  (.clk, .rst_n, .din(vsync_d1),  .dout(vsync_d2));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_hblnk_2  (.clk, .rst_n, .din(hblnk_d1),  .dout(hblnk_d2));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_vblnk_2  (.clk, .rst_n, .din(vblnk_d1),  .dout(vblnk_d2));
    delay #(.WIDTH(12), .CLK_DEL(1)) u_delay_rgb_2    (.clk, .rst_n, .din(rgb_d1),    .dout(rgb_d2));

    // Stage 3
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_is_rect_3(.clk, .rst_n, .din(is_rect_d2),   .dout(is_rect_d3));
    delay #(.WIDTH(11), .CLK_DEL(1)) u_delay_hcount_3 (.clk, .rst_n, .din(hcount_d2), .dout(hcount_d3));
    delay #(.WIDTH(11), .CLK_DEL(1)) u_delay_vcount_3 (.clk, .rst_n, .din(vcount_d2), .dout(vcount_d3));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_hsync_3  (.clk, .rst_n, .din(hsync_d2),  .dout(hsync_d3));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_vsync_3  (.clk, .rst_n, .din(vsync_d2),  .dout(vsync_d3));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_hblnk_3  (.clk, .rst_n, .din(hblnk_d2),  .dout(hblnk_d3));
    delay #(.WIDTH(1),  .CLK_DEL(1)) u_delay_vblnk_3  (.clk, .rst_n, .din(vblnk_d2),  .dout(vblnk_d3));
    delay #(.WIDTH(12), .CLK_DEL(1)) u_delay_rgb_3    (.clk, .rst_n, .din(rgb_d2),    .dout(rgb_d3));


    /**
     * Output Logic
     */

    always_comb begin
        pixel = char_line_pixels[7 - hcount_d3[2:0]];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vga_out.hcount <= '0;
            vga_out.vcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vsync  <= '0;
            vga_out.hblnk  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.rgb    <= '0;
        end else begin
            vga_out.hcount <= hcount_d3;
            vga_out.vcount <= vcount_d3;
            vga_out.hsync  <= hsync_d3;
            vga_out.vsync  <= vsync_d3;
            vga_out.hblnk  <= hblnk_d3;
            vga_out.vblnk  <= vblnk_d3;
            
            if (is_rect_d3 && pixel && !hblnk_d3 && !vblnk_d3)
                vga_out.rgb <= 12'hf_f_f;
            else
                vga_out.rgb <= rgb_d3;
        end
    end

endmodule
