`timescale 1ns / 1ps

/*
 * Uniwersalny moduł eliminacji drgań styków (Debouncer) z detekcją zbocza.
 */
module button_debouncer #(
    parameter CYCLES = 1_000_000 // Domyślnie 10 ms przy zegarze 100 MHz
)(
    input  logic clk,
    input  logic rst,
    input  logic btn_in,
    
    output logic btn_out_state, // Stabilny stan przycisku (poziom)
    output logic btn_out_pulse  // 1-taktowy impuls przy wciśnięciu (zbocze)
);

    // Automatyczne wyliczenie szerokości licznika na podstawie parametru CYCLES
    logic [$clog2(CYCLES+1)-1:0] counter = 0;
    logic prev_state = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            counter       <= 0;
            btn_out_state <= 0;
            prev_state    <= 0;
        end else begin
            
            prev_state <= btn_out_state;
            
            // Logika debouncingu
            if (btn_in != btn_out_state) begin
                counter <= counter + 1;
                if (counter == CYCLES) begin
                    btn_out_state <= btn_in; 
                    counter <= 0;
                end
            end else begin
                
                counter <= 0;
            end
        end
    end

    // Generowanie impulsu tylko przy stabilnym przejściu z 0 na 1
    assign btn_out_pulse = (btn_out_state == 1'b1) && (prev_state == 1'b0);

endmodule