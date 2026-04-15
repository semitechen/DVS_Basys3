interface vga_if;
    timeunit 1ns;
    timeprecision 1ps;
    
    logic [10:0] vcount;
    logic        vsync;
    logic        vblnk;
    logic [10:0] hcount;
    logic        hsync;
    logic        hblnk;
    logic [11:0] rgb;
    

    modport in (
        input vcount, vsync, vblnk, hcount, hsync, hblnk, rgb
    );

    modport out (
        output vcount, vsync, vblnk, hcount, hsync, hblnk, rgb
    );
endinterface