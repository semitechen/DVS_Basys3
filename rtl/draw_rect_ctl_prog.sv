module draw_rect_ctl_prog (
    output logic clk,
    output logic rst_n,
    output logic mouse_left,
    output logic [11:0] mouse_xpos,
    output logic [11:0] mouse_ypos
);

    timeunit 1ns;
    timeprecision 1ps;

    // Generacja zegara 40 MHz (okres 25 ns)
    initial begin
        clk = 1'b0;
        forever #12.5 clk = ~clk;
    end

    initial begin
        // Inicjalizacja i reset
        rst_n = 1'b0;
        mouse_left = 1'b0;
        mouse_xpos = 12'd300; 
        mouse_ypos = 12'd50; 

        #100ns;
        rst_n = 1'b1;

        
        #10ms;

        $display("Puszczam obiekt (Klikniecie lewego przycisku)");
        mouse_left = 1'b1;

        //2 sekundy
        #2000000000ns;

        $display("Koniec symulacji grawitacji.");
        $finish;
    end

endmodule