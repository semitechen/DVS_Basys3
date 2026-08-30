`timescale 1ns / 1ps

/*
 * Module: variable_speed_player
 * Author: Tomasz Jachymiak (Fixed 48-bit multiplication overflow & BRAM read latency)
 * Description: NCO-based variable speed audio sample reader for 8-bit PCM stream.
 */

module variable_speed_player (
    input  logic        clk,
    input  logic        rst,

    input  logic [7:0]  fifo_rd_data,
    input  logic        fifo_empty,
    output logic        fifo_rd_en,

    // Parametry z układu UART (DVS Control)
    // Format Q4.12: 16'h1000 = 1.0x (normalna prędkość), 16'h0800 = 0.5x, 16'h2000 = 2.0x
    input  logic [15:0] speed_factor,

    // Wyjście próbki audio (8-bit unsigned PCM)
    output logic [7:0]  sample_out
);

    // Bazowy przyrost fazy dla 44.1 kHz przy zegarze 100 MHz:
    // (44100 / 100_000_000) * 2^32 = 1894080.58 ~ 1894125
    localparam logic [31:0] BASE_INCREMENT = 32'd1894125;

    logic [31:0] phase_accumulator;
    logic [47:0] current_increment; 
    logic [32:0] next_phase; // 33 bity, aby złapać moment przepełnienia (carry)
    logic [7:0]  sample_reg;
    logic        fifo_rd_en_d;

    // Obliczanie aktualnego przyrostu z rzutowaniem do 48 bitów, aby zapobiec obcięciu 32-bitowemu
    always_comb begin
        current_increment = (48'(BASE_INCREMENT) * 48'(speed_factor)) >> 12;
        next_phase = phase_accumulator + current_increment[31:0];
    end

    // Akumulator fazy i potokowy odczyt z bufora
    always_ff @(posedge clk) begin
        if (rst) begin
            phase_accumulator <= 0;
            fifo_rd_en        <= 0;
            fifo_rd_en_d      <= 0;
            sample_reg        <= 8'd128; // Cisza analogowa (środek skali dla 8-bit unsigned)
        end else begin
            
            // Domyślnie brak odczytu
            fifo_rd_en <= 0;
            fifo_rd_en_d <= fifo_rd_en; // 1-cyklowe opóźnienie dla synchronicznej pamięci BRAM

            // Jeśli bufor ma dane i płyta winylowa się kręci (prędkość > 0)
            if (!fifo_empty && speed_factor != 0) begin
                // Aktualizacja akumulatora fazy
                phase_accumulator <= next_phase[31:0];
                
                // Jeśli nastąpiło przepełnienie (bit 32 równy 1), generuj żądanie odczytu
                fifo_rd_en <= next_phase[32];
            end

            // Po wygenerowaniu żądania fifo_rd_en, dane pojawiają się w kolejnym cyklu na magistrali BRAM
            if (fifo_rd_en_d) begin
                sample_reg <= fifo_rd_data;
            end
        end
    end

    assign sample_out = sample_reg;

endmodule