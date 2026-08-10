module draw_rect_ctl_tb;

    timeunit 1ns;
    timeprecision 1ps;

    wire clk, rst_n, mouse_left;
    wire [11:0] mouse_xpos, mouse_ypos;
    wire [11:0] out_xpos, out_ypos;

    draw_rect_ctl_prog u_prog (
        .clk        (clk),
        .rst_n      (rst_n),
        .mouse_left (mouse_left),
        .mouse_xpos (mouse_xpos),
        .mouse_ypos (mouse_ypos)
    );

    draw_rect_ctl u_dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .mouse_left (mouse_left),
        .mouse_xpos (mouse_xpos),
        .mouse_ypos (mouse_ypos),
        .xpos       (out_xpos),
        .ypos       (out_ypos)
    );

endmodule