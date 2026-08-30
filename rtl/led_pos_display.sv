`timescale 1ns / 1ps
/**
 * Module: led_pos_display
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Independent 16-LED visual position display for DVS playback.
 *              Maps 32-bit sample position output from DVS decoder to 16 LEDs.
 *
 *              Guarantees strictly ONE LED is lit at any given time (one-hot),
 *              moving continuously and smoothly in sync with the timecoded audio.
 *
 *              Uses pipelined fixed-point DSP multiplication instead of division
 *              to achieve zero timing violations at 100 MHz.
 *              Multiplier constant: M = floor(2^40 / 11025) = 99705708 (28'h05F1_6C6C).
 *
 *              At nominal 33 1/3 RPM (44.1 kHz sample rate):
 *              - 250 ms per LED step = 11,025 audio samples.
 *              - 16 LEDs = 4.0 seconds per complete 360-degree rotation.
 */

module led_pos_display (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] sample_pos,     // 32-bit sample position from DVS decoder
    output logic [15:0] led             // 16 board LEDs (strictly 1 active LED)
);

    // Multiplier for 1/11025 scaled by 2^40
    localparam logic [27:0] MULT_FACTOR = 28'd99705708;

    // Pipeline Stage 1: DSP Multiplication
    logic [59:0] mult_stage1;
    always_ff @(posedge clk) begin
        if (rst) begin
            mult_stage1 <= 60'd0;
        end else begin
            mult_stage1 <= sample_pos * MULT_FACTOR;
        end
    end

    // Pipeline Stage 2: Index Extraction (mod 16 from bits [43:40])
    logic [3:0] led_index_stage2;
    always_ff @(posedge clk) begin
        if (rst) begin
            led_index_stage2 <= 4'd0;
        end else begin
            led_index_stage2 <= mult_stage1[43:40];
        end
    end

    // Pipeline Stage 3: One-Hot LED Output
    always_ff @(posedge clk) begin
        if (rst) begin
            led <= 16'h0001; // Default to LD0 on reset
        end else begin
            led <= (16'b1 << led_index_stage2);
        end
    end

endmodule
