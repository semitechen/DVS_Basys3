`timescale 1ns / 1ps

/*

Author: Tomasz Jachymiak
*/
module track_selector #(
    parameter MAX_TRACKS = 4 
)(
    input  logic        clk,
    input  logic        rst,
    
    input  logic        btn_up_pulse,
    input  logic        btn_down_pulse,
    
    output logic [31:0] start_addr,
    output logic        play_req
);

    logic [7:0] track_idx;
    
    // 1. Logika zmiany numeru utworu
    always_ff @(posedge clk) begin
        if (rst) begin
            track_idx <= 0;
            play_req  <= 0;
        end else begin
            play_req <= 0; // Domyślnie brak żądania
            
            if (btn_up_pulse) begin
                if (track_idx >= MAX_TRACKS - 1) track_idx <= 0;
                else                             track_idx <= track_idx + 1;
                play_req <= 1; // Generujemy impuls
            end 
            else if (btn_down_pulse) begin
                if (track_idx == 0) track_idx <= MAX_TRACKS - 1;
                else                track_idx <= track_idx - 1;
                play_req <= 1; // Generujemy impuls
            end
        end
    end

    // 2. Instancja wygenerowanej tablicy adresów (LUT)
    track_lut lut_inst (
        .track_id(track_idx),
        .start_lba(start_addr)
    );

endmodule