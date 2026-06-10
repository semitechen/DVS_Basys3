/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

module draw_bg (
        input  logic clk,
        input  logic rst_n,

        vga_if.in  vga_in,
        vga_if.out vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */

    logic [11:0] rgb_nxt;


    /**
     * Internal logic
     */

    always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
        if (!rst_n) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.hblnk  <= '0;
            vga_out.rgb    <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.hblnk  <= vga_in.hblnk;
            vga_out.rgb    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        logic draw_T, draw_J1, draw_K, draw_J2;

        //T X: 100-200, Y: 200-400
        draw_T = (vga_in.hcount >= 100 && vga_in.hcount < 200 && vga_in.vcount >= 200 && vga_in.vcount < 220) || // Górna belka
                 (vga_in.hcount >= 140 && vga_in.hcount < 160 && vga_in.vcount >= 220 && vga_in.vcount < 400);   // Pionowy słupek

        // Pierwsze J (X: 220-300, Y: 200-400)
        draw_J1 = (vga_in.hcount >= 280 && vga_in.hcount < 300 && vga_in.vcount >= 200 && vga_in.vcount < 400) || // Prawy słupek
                  (vga_in.hcount >= 220 && vga_in.hcount < 300 && vga_in.vcount >= 380 && vga_in.vcount < 400) || // Dolna belka
                  (vga_in.hcount >= 220 && vga_in.hcount < 240 && vga_in.vcount >= 320 && vga_in.vcount < 400) || // Lewy haczyk
                  (vga_in.hcount >= 220 && vga_in.hcount < 300 && vga_in.vcount >= 200 && vga_in.vcount < 220);   // Górna belka

        //K X: 450-570, Y: 200-400
        draw_K = (vga_in.hcount >= 450 && vga_in.hcount < 470 && vga_in.vcount >= 200 && vga_in.vcount < 400) || // Pionowy słupek
                 (vga_in.hcount >= 470 && vga_in.hcount < 570 && vga_in.vcount >= 300 - (vga_in.hcount - 470) && vga_in.vcount < 320 - (vga_in.hcount - 470)) || // Górne ramię
                 (vga_in.hcount >= 470 && vga_in.hcount < 570 && vga_in.vcount >= 280 + (vga_in.hcount - 470) && vga_in.vcount < 300 + (vga_in.hcount - 470));   // Dolne ramię

        // Drugie J X: 620-700, Y: 200-400
        draw_J2 = (vga_in.hcount >= 680 && vga_in.hcount < 700 && vga_in.vcount >= 200 && vga_in.vcount < 400) || // Prawy słupek
                  (vga_in.hcount >= 620 && vga_in.hcount < 700 && vga_in.vcount >= 380 && vga_in.vcount < 400) || // Dolna belka
                  (vga_in.hcount >= 620 && vga_in.hcount < 640 && vga_in.vcount >= 320 && vga_in.vcount < 400) || // Lewy haczyk
                  (vga_in.hcount >= 620 && vga_in.hcount < 700 && vga_in.vcount >= 200 && vga_in.vcount < 220);   // Górna belka

        if (vga_in.vblnk || vga_in.hblnk) begin
            rgb_nxt = 12'h0_0_0;
        end else begin
            if (vga_in.vcount == 0) rgb_nxt = 12'hf_f_0;
            else if (vga_in.vcount == VER_PIXELS - 1) rgb_nxt = 12'hf_0_0;
            else if (vga_in.hcount == 0) rgb_nxt = 12'h0_f_0;
            else if (vga_in.hcount == HOR_PIXELS - 1) rgb_nxt = 12'h0_0_f;
            else if (draw_T || draw_J1 || draw_K || draw_J2) rgb_nxt = 12'h7_f_d; // aquamarine
            else rgb_nxt = 12'h0_0_0;
        end
    end

endmodule
