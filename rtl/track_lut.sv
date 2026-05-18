// AUTOMATYCZNIE WYGENEROWANY PLIK - NIE EDYTUJ RECZNIE
// Skrypt wav_to_sd.py

`timescale 1ns / 1ps

module track_lut (
    input  logic [7:0]  track_id,
    output logic [31:0] start_lba
);

    always_comb begin
        case (track_id)
            8'd0: start_lba = 32'd0; // Plik: 09_sentino_algeciras.wav
            8'd1: start_lba = 32'd45692; // Plik: 10_sentino_remy_martin.wav
            8'd2: start_lba = 32'd104091; // Plik: 11_sentino_rio.wav
            default: start_lba = 32'd0;
        endcase
    end
endmodule
