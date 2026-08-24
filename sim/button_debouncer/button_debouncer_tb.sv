`timescale 1ns / 1ps

module button_debouncer_tb;

    // Sygnały testowe
    logic clk;
    logic rst;
    logic btn_in;
    
    logic btn_out_state;
    logic btn_out_pulse;

    // Instancja testowanego modułu (UUT)
    button_debouncer #(
        .CYCLES(10) // Nadpisujemy parametr: tylko 10 cykli zegara do stabilizacji (100 ns)
    ) uut (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_in),
        .btn_out_state(btn_out_state),
        .btn_out_pulse(btn_out_pulse)
    );

    // Generowanie zegara 100 MHz (okres 10 ns)
    always #5 clk = ~clk;

    // Wektor testowy
    initial begin
        // 1. Stan początkowy i Reset
        clk = 0;
        rst = 1;
        btn_in = 0;
        
        #20 rst = 0;
        #20;

        // 2. Symulacja drgań styków (bouncing) przy wciskaniu
        // Szpilki są krótsze niż 10 cykli (100 ns)
        btn_in = 1; #12; // Zestyk na chwilę
        btn_in = 0; #8;  // Puszcza
        btn_in = 1; #15; // Znowu łapie
        btn_in = 0; #25; // Puszcza
        
        // 3. Stabilne wciśnięcie przycisku
        btn_in = 1;
        
        // Czekamy wystarczająco długo, aby debouncer zareagował (grubo ponad 100 ns)
        #200; 

        // 4. Symulacja drgań styków przy puszczaniu przycisku
        btn_in = 0; #10;
        btn_in = 1; #12;
        btn_in = 0; 
        
        // Koniec symulacji
        #100;
        $finish;
    end

endmodule