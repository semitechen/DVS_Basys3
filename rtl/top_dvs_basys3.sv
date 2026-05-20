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
    input  logic vauxn6,
    input  logic vauxp14,
    input  logic vauxn14
);

    // --- TYMCZASOWA LOGIKA DO TESTU BOJOWEGO ---
    // Przypisujemy bezpieczne, stałe wartości do wyjść, 
    // aby Vivado nie krzyczało o "wiszących" (floating) pinach.
    
    assign sd_cs   = 1'b1; 
    assign sd_mosi = 1'b0;
    assign sd_sck  = 1'b0;

    logic [11:0] adc_data_l;
    logic [11:0] adc_data_r;
    logic        adc_data_valid;

    xadc_interface xadc_inst (
        .clk(clk),
        .rst(rst),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .data_l(adc_data_l),
        .data_r(adc_data_r),
        .data_valid(adc_data_valid)
    );

endmodule