`timescale 1ns / 1ps
/**
 * Module: led_pos_display
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: High-speed, zero-DSP 16-LED visual position display for DVS playback.
 *              Maps sample position from DVS decoder smoothly to 16 LEDs.
 */

module led_pos_display (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] sample_pos,     // 32-bit sample position from DVS decoder
    output logic [15:0] led             // 16 board LEDs (strictly 1 active LED)
);

    logic [3:0] led_index;

    always_ff @(posedge clk) begin
        if (rst) begin
            led_index <= 4'd0;
            led       <= 16'h0001;
        end else begin
            led_index <= sample_pos[17:14];
            led       <= (16'b1 << led_index);
        end
    end

endmodule
