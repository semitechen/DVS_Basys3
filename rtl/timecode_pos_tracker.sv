`timescale 1ns / 1ps
/**
 * Module: timecode_pos_tracker
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Pure DVS Relative Mode Decoding Engine (4x Quadrature Resolution).
 *              Digitizes and decodes Serato 1 kHz Quadrature Timecode from XADC inputs
 *              and tracks needle position in 44.1 kHz audio sample units.
 *
 * Robust Noise Immunity & Silence Detection:
 *  1. 32-bit Fixed-Point Dynamic DC Estimator (zero DC offset, no bit-width overflow).
 *  2. Dual Schmitt-Trigger Hysteresis (Left & Right) with parameterizable threshold.
 *  3. Fast-Attack / Slow-Decay Envelope Squelch Gate (silence squelch ~120mV).
 *  4. 4x Gray-Code Quadrature State Machine (11.025 samples per quarter-cycle step).
 *  5. 32.32 Fixed-Point Sub-Sample Position Accumulator.
 */

module timecode_pos_tracker #(
    parameter signed [12:0] HYSTERESIS        = 13'sd80, // Noise immunity threshold (~65mV)
    parameter logic  [15:0] SQUELCH_THRESHOLD = 16'd150  // Squelch threshold for silence/stop (~120mV)
)(
    input  logic        clk,            // 100 MHz System Clock
    input  logic        rst,            // Reset / Zero position
    input  logic [11:0] data_l,         // 12-bit unsigned ADC sample Left
    input  logic [11:0] data_r,         // 12-bit unsigned ADC sample Right
    input  logic        data_valid,     // ADC sample strobe (~44.1 kHz - 100 kHz)

    output logic [31:0] sample_pos,     // Track position in 44.1 kHz audio samples
    output logic        direction       // 1 = Forward (33 1/3 RPM), 0 = Reverse
);

    // --- 1. 32-bit Dynamic DC Offset Tracking (1st-Order IIR Low-Pass DC Estimator) ---
    // 32-bit signed fixed point: [31:12] integer, [11:0] fraction
    // Alpha = 1/256 (shift by 8)
    logic signed [31:0] dc_est_l;
    logic signed [31:0] dc_est_r;
    logic signed [12:0] ac_l;
    logic signed [12:0] ac_r;

    always_ff @(posedge clk) begin
        if (rst) begin
            dc_est_l <= 32'sd2048 <<< 12;
            dc_est_r <= 32'sd2048 <<< 12;
            ac_l     <= 13'sd0;
            ac_r     <= 13'sd0;
        end else if (data_valid) begin
            // 32-bit signed differences (zero risk of overflow for 12-bit ADC data 0..4095)
            dc_est_l <= dc_est_l + ((($signed({1'b0, data_l}) <<< 12) - dc_est_l) >>> 8);
            dc_est_r <= dc_est_r + ((($signed({1'b0, data_r}) <<< 12) - dc_est_r) >>> 8);

            // Compute zero-centered AC signal
            ac_l <= $signed({1'b0, data_l}) - $signed(dc_est_l[24:12]);
            ac_r <= $signed({1'b0, data_r}) - $signed(dc_est_r[24:12]);
        end
    end


    // --- 2. Signal Presence & Envelope Squelch Gate (Eliminates Idle Drift) ---
    logic [12:0] abs_l, abs_r;
    assign abs_l = (ac_l < 0) ? -ac_l : ac_l;
    assign abs_r = (ac_r < 0) ? -ac_r : ac_r;

    logic [23:0] envelope; // 24-bit accumulator with 10 fractional bits
    logic signal_present;

    always_ff @(posedge clk) begin
        if (rst) begin
            envelope       <= 24'd0;
            signal_present <= 1'b0;
        end else if (data_valid) begin
            logic [12:0] max_amp;
            max_amp = (abs_l > abs_r) ? abs_l : abs_r;

            // Fast attack, slow decay (~5 ms time constant)
            if ({1'b0, max_amp, 10'b0} > envelope) begin
                envelope <= {1'b0, max_amp, 10'b0};
            end else if (envelope > 24'd0) begin
                envelope <= envelope - (envelope >> 8) - 24'd1;
            end

            signal_present <= (envelope[22:10] >= SQUELCH_THRESHOLD);
        end
    end


    // --- 3. Dual Schmitt-Trigger & 4x Quadrature State Machine ---
    logic state_a, state_b;
    logic next_a, next_b;

    // Combinatorial Schmitt trigger logic with hysteresis
    always_comb begin
        next_a = state_a;
        if (ac_l > HYSTERESIS)
            next_a = 1'b1;
        else if (ac_l < -HYSTERESIS)
            next_a = 1'b0;

        next_b = state_b;
        if (ac_r > HYSTERESIS)
            next_b = 1'b1;
        else if (ac_r < -HYSTERESIS)
            next_b = 1'b0;
    end

    logic [1:0] curr_quad;
    logic [1:0] next_quad;
    assign curr_quad = {state_a, state_b};
    assign next_quad = {next_a, next_b};

    logic fwd_step;
    logic rev_step;
    logic dir_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_a   <= 1'b0;
            state_b   <= 1'b0;
            fwd_step  <= 1'b0;
            rev_step  <= 1'b0;
            dir_reg   <= 1'b1;
        end else if (data_valid) begin
            state_a <= next_a;
            state_b <= next_b;

            if (signal_present) begin
                case ({curr_quad, next_quad})
                    // Forward transitions: (0,0) -> (0,1) -> (1,1) -> (1,0) -> (0,0)
                    4'b00_01,
                    4'b01_11,
                    4'b11_10,
                    4'b10_00: begin
                        fwd_step <= 1'b1;
                        rev_step <= 1'b0;
                        dir_reg  <= 1'b1;
                    end

                    // Reverse transitions: (0,0) -> (1,0) -> (1,1) -> (0,1) -> (0,0)
                    4'b00_10,
                    4'b10_11,
                    4'b11_01,
                    4'b01_00: begin
                        fwd_step <= 1'b0;
                        rev_step <= 1'b1;
                        dir_reg  <= 1'b0;
                    end

                    // Stationary or invalid diagonal jumps (noise reject)
                    default: begin
                        fwd_step <= 1'b0;
                        rev_step <= 1'b0;
                    end
                endcase
            end else begin
                fwd_step <= 1'b0;
                rev_step <= 1'b0;
            end
        end else begin
            fwd_step <= 1'b0;
            rev_step <= 1'b0;
        end
    end

    assign direction = dir_reg;


    // --- 4. High-Precision Fractional Sample Position Accumulator (32.32 Fixed-Point) ---
    // 1 cycle of 1000 Hz timecode @ 44.1 kHz Fs = 44.1 samples
    // 1 quadrature step (1/4 cycle) = 11.025 samples
    // 11.025 in 32.32 fixed-point = 11 * 2^32 + 0.025 * 2^32 = 47351658496 (64'h0000_000B_0666_6666)
    localparam logic [63:0] SAMPLES_PER_STEP_FP = 64'h0000_000B_0666_6666;

    logic [63:0] pos_fp; // 32-bit integer . 32-bit fraction

    always_ff @(posedge clk) begin
        if (rst) begin
            pos_fp <= 64'd0;
        end else begin
            if (fwd_step) begin
                pos_fp <= pos_fp + SAMPLES_PER_STEP_FP;
            end else if (rev_step) begin
                if (pos_fp >= SAMPLES_PER_STEP_FP)
                    pos_fp <= pos_fp - SAMPLES_PER_STEP_FP;
                else
                    pos_fp <= 64'd0;
            end
        end
    end

    // Integer part of current sample position
    assign sample_pos = pos_fp[63:32];

endmodule
