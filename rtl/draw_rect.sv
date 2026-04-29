module draw_rect #(
    parameter int WIDTH = 48,
    parameter int HEIGHT = 64,
    parameter int THICKNESS = 4, 
    parameter logic [11:0] COLOR = 12'hf_0_0 
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    
    output logic [11:0] pixel_addr,
    input  logic [11:0] rgb_pixel,
    
    vga_if.in  vga_in,
    vga_if.out vga_out
);

timeunit 1ns;
timeprecision 1ps;

    logic inside_outer;
    logic inside_inner;

    logic [10:0] hcount_d1, vcount_d1;
    logic vsync_d1, hsync_d1, vblnk_d1, hblnk_d1;
    logic [11:0] bg_rgb_d1;
    logic is_border_d1;
    logic is_image_d1;

    
    assign pixel_addr = (vga_in.vcount - y_pos) * 48 + (vga_in.hcount - x_pos);

    always_comb begin
        inside_outer = (vga_in.hcount >= x_pos) &&
                       (vga_in.hcount < (x_pos + WIDTH)) &&
                       (vga_in.vcount >= y_pos) &&
                       (vga_in.vcount < (y_pos + HEIGHT));

        inside_inner = (vga_in.hcount >= (x_pos + THICKNESS)) &&
                       (vga_in.hcount < (x_pos + WIDTH - THICKNESS)) &&
                       (vga_in.vcount >= (y_pos + THICKNESS)) &&
                       (vga_in.vcount < (y_pos + HEIGHT - THICKNESS));
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcount_d1 <= '0; vcount_d1 <= '0;
            vsync_d1  <= '0; hsync_d1  <= '0;
            vblnk_d1  <= '0; hblnk_d1  <= '0;
            bg_rgb_d1 <= '0;
            is_border_d1 <= '0; is_image_d1 <= '0;
            
            vga_out.vcount <= '0; vga_out.vsync  <= '0; vga_out.vblnk <= '0;
            vga_out.hcount <= '0; vga_out.hsync  <= '0; vga_out.hblnk <= '0;
            vga_out.rgb    <= '0;
        end else begin
            hcount_d1 <= vga_in.hcount;
            vcount_d1 <= vga_in.vcount;
            vsync_d1  <= vga_in.vsync;
            hsync_d1  <= vga_in.hsync;
            vblnk_d1  <= vga_in.vblnk;
            hblnk_d1  <= vga_in.hblnk;
            bg_rgb_d1 <= vga_in.rgb;
            
            is_border_d1 <= inside_outer && !inside_inner;
            is_image_d1  <= inside_inner;

            vga_out.hcount <= hcount_d1;
            vga_out.vcount <= vcount_d1;
            vga_out.vsync  <= vsync_d1;
            vga_out.hsync  <= hsync_d1;
            vga_out.vblnk  <= vblnk_d1;
            vga_out.hblnk  <= hblnk_d1;


            if (is_border_d1)
                vga_out.rgb <= COLOR;        
            else if (is_image_d1)
                vga_out.rgb <= rgb_pixel;    
            else
                vga_out.rgb <= bg_rgb_d1;  
        end
    end

endmodule