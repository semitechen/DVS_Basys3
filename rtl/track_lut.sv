// AUTOMATYCZNIE WYGENEROWANY PLIK
`timescale 1ns / 1ps

module track_lut (
    input  logic [7:0]  track_id,
    output logic [31:0] start_lba
);
    always_comb begin
        case (track_id)
            8'd0: start_lba = 32'd0;
            8'd1: start_lba = 32'd29532;
            8'd2: start_lba = 32'd48325;
            default: start_lba = 32'd0;
        endcase
    end
endmodule
