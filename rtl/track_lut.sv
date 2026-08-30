// AUTOMATYCZNIE WYGENEROWANY PLIK - NIE EDYTUJ RECZNIE
// Skrypt wav_to_sd.py

`timescale 1ns / 1ps

module track_lut (
    input  logic [7:0]  track_id,
    output logic [31:0] start_lba
);

    always_comb begin
        case (track_id)
            8'd0: start_lba = 32'd0;     // Plik: dj blik - balsam.wav
            8'd1: start_lba = 32'd29532; // Plik: dj blik - h2o feat. dominika plonka.wav
            8'd2: start_lba = 32'd48325; // Plik: dj blik - horyzont.wav
            default: start_lba = 32'd0;
        endcase
    end
endmodule
