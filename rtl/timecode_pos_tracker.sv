`timescale 1ns / 1ps
/**
 * Module: timecode_pos_tracker
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Pure DVS Relative Mode Decoding Engine (4x Quadrature Resolution).
 *              Digitizes and decodes Serato 1 kHz Quadrature Timecode from XADC inputs
 *              and tracks needle position, playback direction, and speed factor.
 *
 * Robust Noise Immunity & Silence Detection:
 *  1. 32-bit Fixed-Point Dynamic DC Estimator (zero DC offset, no bit-width overflow).
 *  2. Dual Schmitt-Trigger Hysteresis (Left & Right) with parameterizable threshold.
 *  3. Fast-Attack / Slow-Decay Envelope Squelch Gate (silence squelch ~120mV).
 *  4. 4x Gray-Code Quadrature State Machine (11.025 samples per quarter-cycle step).
 *  5. 32.32 Fixed-Point Sub-Sample Position Accumulator.
 *  6. Real-Time Variable Speed Factor Estimator (Q4.12: 16'h1000 = 1.0x).
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
    output logic        direction,      // 1 = Forward (33 1/3 RPM), 0 = Reverse
    output logic [15:0] speed_factor,   // Playback speed in Q4.12 (16'h1000 = 1.0x, 16'h0000 = 0.0x)
    output logic        signal_present_out // Squelch gate active indicator
);

    // --- 1. 32-bit Dynamic DC Offset Tracking (1st-Order IIR Low-Pass DC Estimator) ---
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
            dc_est_l <= dc_est_l + ((($signed({1'b0, data_l}) <<< 12) - dc_est_l) >>> 8);
            dc_est_r <= dc_est_r + ((($signed({1'b0, data_r}) <<< 12) - dc_est_r) >>> 8);

            ac_l <= $signed({1'b0, data_l}) - $signed(dc_est_l[24:12]);
            ac_r <= $signed({1'b0, data_r}) - $signed(dc_est_r[24:12]);
        end
    end


    // --- 2. Signal Presence & Envelope Squelch Gate ---
    logic [12:0] abs_l, abs_r;
    assign abs_l = (ac_l < 0) ? -ac_l : ac_l;
    assign abs_r = (ac_r < 0) ? -ac_r : ac_r;

    logic [23:0] envelope;
    logic signal_present;

    always_ff @(posedge clk) begin
        if (rst) begin
            envelope       <= 24'd0;
            signal_present <= 1'b0;
        end else if (data_valid) begin
            logic [12:0] max_amp;
            max_amp = (abs_l > abs_r) ? abs_l : abs_r;

            if ({1'b0, max_amp, 10'b0} > envelope) begin
                envelope <= {1'b0, max_amp, 10'b0};
            end else if (envelope > 24'd0) begin
                envelope <= envelope - (envelope >> 8) - 24'd1;
            end

            signal_present <= (envelope[22:10] >= SQUELCH_THRESHOLD);
        end
    end

    assign signal_present_out = signal_present;


    // --- 3. Dual Schmitt-Trigger & 4x Quadrature State Machine ---
    logic state_a, state_b;
    logic next_a, next_b;

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
    localparam logic [63:0] SAMPLES_PER_STEP_FP = 64'h0000_000B_0666_6666; // 11.025 samples

    logic [63:0] pos_fp;

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

    assign sample_pos = pos_fp[63:32];


    // --- 5. Real-Time DVS Speed Factor Estimator (Q4.12 Format) ---
    // At nominal 1.0x speed, 4 quadrature steps per 1000 Hz cycle = 25,000 clock cycles @ 100 MHz.
    // Base constant: 25,000 * 4096 = 102,400,000 (27'd102_400_000).
    // Timeout for stopped vinyl: 2,500,000 cycles (25 ms timeout = 0.01x minimum speed cutoff).
    localparam logic [23:0] STEP_TIMEOUT = 24'd2_500_000;

    logic [23:0] step_timer;
    logic [23:0] last_step_period;
    logic [15:0] instantaneous_speed;
    logic [15:0] filtered_speed;

    always_ff @(posedge clk) begin
        if (rst) begin
            step_timer          <= 24'd0;
            last_step_period    <= 24'd25_000;
            instantaneous_speed <= 16'd0;
            filtered_speed      <= 16'd0;
        end else begin
            if (fwd_step || rev_step) begin
                last_step_period <= (step_timer > 24'd1000) ? step_timer : 24'd1000;
                step_timer       <= 24'd0;
            end else if (step_timer < STEP_TIMEOUT) begin
                step_timer <= step_timer + 24'd1;
            end

            // Instantaneous speed calculation (clamped to 4.0x max = 16'h4000)
            if (!signal_present || step_timer >= STEP_TIMEOUT) begin
                instantaneous_speed <= 16'd0;
            end else begin
                // Fast fixed-point division: 102,400,000 / last_step_period
                if (last_step_period <= 24'd6_250) begin
                    instantaneous_speed <= 16'h4000; // 4.0x cap
                end else begin
                    instantaneous_speed <= 28'd102_400_000 / last_step_period;
                end
            end

            // 1st-Order IIR Low-Pass Smoothing Filter on Speed Factor (Leaky Integrator)
            // filtered = filtered + (instantaneous - filtered) / 8
            filtered_speed <= filtered_speed + $signed(($signed({1'b0, instantaneous_speed}) - $signed({1'b0, filtered_speed})) >>> 3);
        end
    end

    assign speed_factor = filtered_speed;

endmodule
