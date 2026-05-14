`timescale 1ns / 1ps

module top_dvs_basys3 (
    // Zegar i reset
    input  logic clk,
    input  logic rst,

    // Przyciski interfejsu użytkownika
    input  logic btn_up,
    input  logic btn_down,

    // Interfejs SPI karty SD (Pmod JC)
    output logic sd_cs,
    output logic sd_mosi,
    input  logic sd_miso,
    output logic sd_sck,

    // Wejście analogowe z gramofonu (Pmod JXADC)
    input  logic vauxp6,
    input  logic vauxn6
);

    // --- TYMCZASOWA LOGIKA DO TESTU BOJOWEGO ---
    // Przypisujemy bezpieczne, stałe wartości do wyjść, 
    // aby Vivado nie krzyczało o "wiszących" (floating) pinach.
    
    assign sd_cs   = 1'b1; // Aktywny stan niski, więc 1 oznacza brak komunikacji
    assign sd_mosi = 1'b0;
    assign sd_sck  = 1'b0;

endmodule