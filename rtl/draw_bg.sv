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

        input  logic [10:0] vcount_in,
        input  logic        vsync_in,
        input  logic        vblnk_in,
        input  logic [10:0] hcount_in,
        input  logic        hsync_in,
        input  logic        hblnk_in,

        output logic [10:0] vcount_out,
        output logic        vsync_out,
        output logic        vblnk_out,
        output logic [10:0] hcount_out,
        output logic        hsync_out,
        output logic        hblnk_out,

        output logic [11:0] rgb_out
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
            vcount_out <= '0;
            vsync_out  <= '0;
            vblnk_out  <= '0;
            hcount_out <= '0;
            hsync_out  <= '0;
            hblnk_out  <= '0;
            rgb_out    <= '0;
        end else begin
            vcount_out <= vcount_in;
            vsync_out  <= vsync_in;
            vblnk_out  <= vblnk_in;
            hcount_out <= hcount_in;
            hsync_out  <= hsync_in;
            hblnk_out  <= hblnk_in;
            rgb_out    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        logic draw_T, draw_J1, draw_K, draw_J2;

        //T X: 100-200, Y: 200-400
        draw_T = (hcount_in >= 100 && hcount_in < 200 && vcount_in >= 200 && vcount_in < 220) || // Górna belka
                 (hcount_in >= 140 && hcount_in < 160 && vcount_in >= 220 && vcount_in < 400);   // Pionowy słupek

        // Pierwsze J (X: 220-300, Y: 200-400)
        draw_J1 = (hcount_in >= 280 && hcount_in < 300 && vcount_in >= 200 && vcount_in < 400) || // Prawy słupek
                  (hcount_in >= 220 && hcount_in < 300 && vcount_in >= 380 && vcount_in < 400) || // Dolna belka
                  (hcount_in >= 220 && hcount_in < 240 && vcount_in >= 320 && vcount_in < 400) || // Lewy haczyk
                  (hcount_in >= 220 && hcount_in < 300 && vcount_in >= 200 && vcount_in < 220);   // Górna belka

        //K X: 450-570, Y: 200-400
        draw_K = (hcount_in >= 450 && hcount_in < 470 && vcount_in >= 200 && vcount_in < 400) || // Pionowy słupek
                 (hcount_in >= 470 && hcount_in < 570 && vcount_in >= 300 - (hcount_in - 470) && vcount_in < 320 - (hcount_in - 470)) || // Górne ramię
                 (hcount_in >= 470 && hcount_in < 570 && vcount_in >= 280 + (hcount_in - 470) && vcount_in < 300 + (hcount_in - 470));   // Dolne ramię

        // Drugie J X: 620-700, Y: 200-400
        draw_J2 = (hcount_in >= 680 && hcount_in < 700 && vcount_in >= 200 && vcount_in < 400) || // Prawy słupek
                  (hcount_in >= 620 && hcount_in < 700 && vcount_in >= 380 && vcount_in < 400) || // Dolna belka
                  (hcount_in >= 620 && hcount_in < 640 && vcount_in >= 320 && vcount_in < 400) || // Lewy haczyk
                  (hcount_in >= 620 && hcount_in < 700 && vcount_in >= 200 && vcount_in < 220);   // Górna belka

        if (vblnk_in || hblnk_in) begin
            rgb_nxt = 12'h0_0_0;
        end else begin
            if (vcount_in == 0) rgb_nxt = 12'hf_f_0;
            else if (vcount_in == VER_PIXELS - 1) rgb_nxt = 12'hf_0_0;
            else if (hcount_in == 0) rgb_nxt = 12'h0_f_0;
            else if (hcount_in == HOR_PIXELS - 1) rgb_nxt = 12'h0_0_f;
            else if (draw_T || draw_J1 || draw_K || draw_J2) rgb_nxt = 12'h7_f_d; // aquamarine
            else rgb_nxt = 12'h0_0_0;
        end
    end

endmodule
