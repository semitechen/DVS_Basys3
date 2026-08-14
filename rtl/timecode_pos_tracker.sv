`timescale 1ns / 1ps
/**
 * Module: timecode_pos_tracker
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Decodes Serato 1 kHz Quadrature Timecode from XADC inputs
 *              and tracks needle position in 44.1 kHz audio sample units.
 *
 *              Uses Schmitt-Trigger Hysteresis to reject idle noise.
 *              At standard 33 1/3 RPM (1000 Hz carrier):
 *              - 1 cycle of 1000 Hz = 44.1 audio samples.
 *              - 250 ms of playback = 11,025 audio samples.
 *              - Drives 16 LEDs sequentially (only 1 LED lit at a time, 250 ms step @ 1.0x speed).
 */

module timecode_pos_tracker #(
    parameter signed [12:0] HYSTERESIS = 13'sd50 // Noise immunity threshold (~40mV)
)(
    input  logic        clk,            // 100 MHz System Clock
    input  logic        rst,            // Reset / Zero position
    input  logic [11:0] data_l,         // 12-bit unsigned ADC sample Left
    input  logic [11:0] data_r,         // 12-bit unsigned ADC sample Right
    input  logic        data_valid,     // ADC sample strobe (~44.1 kHz - 100 kHz)

    output logic [31:0] sample_pos,     // Track position in 44.1 kHz audio samples
    output logic        direction,      // 1 = Forward (33 1/3 RPM), 0 = Reverse
    output logic [15:0] led_display     // 16 LEDs step display (only 1 LED lit at a time, 250 ms step @ 33.3 RPM)
);

    // --- 1. DC Offset Removal (Mid-scale ~2048 for 12-bit ADC) ---
    logic signed [12:0] ac_l, ac_r;
    always_ff @(posedge clk) begin
        if (rst) begin
            ac_l <= 0;
            ac_r <= 0;
        end else if (data_valid) begin
            ac_l <= $signed({1'b0, data_l}) - 13'sd2048;
            ac_r <= $signed({1'b0, data_r}) - 13'sd2048;
        end
    end

    // --- 2. Schmitt-Trigger Hysteresis Zero-Crossing Detector ---
    logic armed;
    logic zero_cross_pos;

    always_ff @(posedge clk) begin
        if (rst) begin
            armed          <= 1'b0;
            zero_cross_pos <= 1'b0;
        end else if (data_valid) begin
            if (ac_l < -HYSTERESIS) begin
                armed          <= 1'b1; // Signal dropped below negative threshold, arm detector
                zero_cross_pos <= 1'b0;
            end else if (armed && (ac_l > HYSTERESIS)) begin
                armed          <= 1'b0; // Trigger valid zero crossing
                zero_cross_pos <= 1'b1;
            end else begin
                zero_cross_pos <= 1'b0;
            end
        end else begin
            zero_cross_pos <= 1'b0;
        end
    end

    // Quadrature Direction: at Left positive zero-crossing, if Right > 0 => Forward, else Reverse
    logic fwd_dir;
    always_ff @(posedge clk) begin
        if (rst) begin
            fwd_dir <= 1'b1;
        end else if (zero_cross_pos) begin
            fwd_dir <= (ac_r > 0);
        end
    end
    assign direction = fwd_dir;


    // --- 3. Fractional Sample Position Accumulator ---
    // 1 cycle of 1000 Hz timecode @ 44.1 kHz Fs = 44.1 samples
    // Represented in 16.16 fixed-point: 44.1 * 65536 = 2890137 (32'h002C1999)
    localparam logic [31:0] SAMPLES_PER_CYCLE_FP = 32'd2890137;

    logic [47:0] pos_fp; // 32-bit integer . 16-bit fraction

    always_ff @(posedge clk) begin
        if (rst) begin
            pos_fp <= 48'd0;
        end else if (zero_cross_pos) begin
            if (fwd_dir) begin
                pos_fp <= pos_fp + SAMPLES_PER_CYCLE_FP;
            end else begin
                if (pos_fp >= SAMPLES_PER_CYCLE_FP)
                    pos_fp <= pos_fp - SAMPLES_PER_CYCLE_FP;
                else
                    pos_fp <= 48'd0;
            end
        end
    end

    // Integer part of current sample position
    assign sample_pos = pos_fp[47:16];


    // --- 4. Sequential LED Step Display (Only 1 LED lit at a time, 250 ms step @ 33 1/3 RPM) ---
    // 250 ms @ 44.1 kHz = 11,025 samples
    // 16 LEDs step: step_index = (sample_pos / 11025) % 16
    logic [3:0] led_index;
    always_comb begin
        led_index = (sample_pos / 32'd11025) % 16;
    end

    // One-hot single LED output (strictly 1 LED lit at a time)
    assign led_display = (16'b1 << led_index);

endmodule
