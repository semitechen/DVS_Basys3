module draw_rect #(
    parameter int WIDTH = 640,
    parameter int HEIGHT = 240,
    parameter int THICKNESS = 10,
    parameter logic [11:0] COLOR = 12'hf_0_0 
)(
    input  logic clk,
    input  logic rst_n,
    input logic x_pos,
    input logic y_pos,
    vga_if.in  vga_in,
    vga_if.out vga_out
);

timeunit 1ns;
timeprecision 1ps;

    logic inside_outer;
    logic inside_inner;
    logic [11:0] rgb_nxt;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vga_out.vcount <= 11'b0;
            vga_out.vsync  <= 1'b0;
            vga_out.vblnk  <= 1'b0;
            vga_out.hcount <= 11'b0;
            vga_out.hsync  <= 1'b0;
            vga_out.hblnk  <= 1'b0;
            vga_out.rgb    <= 12'b0;
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

    always_comb begin
        inside_outer = (vga_in.hcount >= x_pos) &&
                       (vga_in.hcount < (x_pos + WIDTH)) &&
                       (vga_in.vcount >= y_pos) &&
                       (vga_in.vcount < (y_pos + HEIGHT));

        inside_inner = (vga_in.hcount >= (x_pos + THICKNESS)) &&
                       (vga_in.hcount < (x_pos + WIDTH - THICKNESS)) &&
                       (vga_in.vcount >= (y_pos + THICKNESS)) &&
                       (vga_in.vcount < (y_pos + HEIGHT - THICKNESS));

        if (inside_outer && !inside_inner) begin
            rgb_nxt = COLOR;
        end else begin
             rgb_nxt = vga_in.rgb;
        end
    end

    

endmodule
