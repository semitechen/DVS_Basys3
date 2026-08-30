`timescale 1ns / 1ps
/**
 * Module: r2r_dac
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Production High-Fidelity 8-Bit R-2R Resistor Ladder Audio DAC Engine.
 *              Takes 8-bit or 16-bit audio sample amplitude as input and produces
 *              an ultra-clean, unconditionally stable 8-bit output bus for the external
 *              R-2R resistor ladder.
 *
 * DSP Architecture:
 *  - 16x Oversampling (~704.2 kHz update rate @ 100 MHz clock).
 *  - Unconditionally Stable 1st-Order Error-Feedback Noise Shaping: H(z) = 1 - z^-1.
 *  - Dual-LFSR Triangular Probability Density Function (TPDF) Dithering.
 *  - Fast Shift-Based Digital Headroom Scaling (-0.56 dBFS, [2048..63488]) with zero DSPs.
 *  - Direct IOB registered output for zero skew and maximum noise immunity.
 */

module r2r_dac #(
    parameter int INPUT_WIDTH  = 8,    // Input sample bit width (8 to 16)
    parameter bit SIGNED_INPUT = 1'b0  // 0 = unsigned [0..2^N-1], 1 = 2's complement signed
)(
    input  logic                   clk,        // 100 MHz System Clock
    input  logic                   rst,        // Synchronous Reset
    input  logic [INPUT_WIDTH-1:0] sample_in,  // Audio sample amplitude
    output logic [7:0]             dac_out     // 8-bit physical R-2R DAC output bus [dac7..dac0]
);

    // 1. Normalize input sample to 16-bit unsigned domain [0..65535]
    logic [15:0] raw_u16;

    generate
        if (INPUT_WIDTH == 16) begin : gen_w16
            if (SIGNED_INPUT) begin : gen_signed
                assign raw_u16 = {~sample_in[15], sample_in[14:0]};
            end else begin : gen_unsigned
                assign raw_u16 = sample_in;
            end
        end else if (INPUT_WIDTH == 8) begin : gen_w8
            if (SIGNED_INPUT) begin : gen_signed
                assign raw_u16 = {~sample_in[7], sample_in[6:0], 8'b0};
            end else begin : gen_unsigned
                assign raw_u16 = {sample_in, 8'b0};
            end
        end else begin : gen_generic
            if (SIGNED_INPUT) begin : gen_signed
                assign raw_u16 = {~sample_in[INPUT_WIDTH-1], sample_in[INPUT_WIDTH-2:0], {(16-INPUT_WIDTH){1'b0}}};
            end else begin : gen_unsigned
                assign raw_u16 = {sample_in, {(16-INPUT_WIDTH){1'b0}}};
            end
        end
    endgenerate

    // 2. Fast Shift-Based Digital Headroom Scaling (-0.56 dBFS, ~0.9375 scale):
    // Maps [0..65535] to [2048..63488] with exact midpoint at 32768
    // scaled = 2048 + raw_u16 - (raw_u16 >> 4)
    logic [15:0] scaled_sample;
    always_ff @(posedge clk) begin
        if (rst) begin
            scaled_sample <= 16'h8000;
        end else begin
            scaled_sample <= 16'd2048 + raw_u16 - {4'b0, raw_u16[15:4]};
        end
    end

    // 3. 16x Oversampling Strobe Generator: 100 MHz / 142 ~ 704.2 kHz (16x 44.1 kHz)
    logic [7:0] os_cnt;
    logic       os_strobe;

    always_ff @(posedge clk) begin
        if (rst) begin
            os_cnt    <= 8'd0;
            os_strobe <= 1'b0;
        end else begin
            if (os_cnt >= 8'd141) begin
                os_cnt    <= 8'd0;
                os_strobe <= 1'b1;
            end else begin
                os_cnt    <= os_cnt + 8'd1;
                os_strobe <= 1'b0;
            end
        end
    end

    // 4. 16-bit Galois LFSR PRNG for TPDF Dither Generation
    logic [15:0] lfsr1, lfsr2;
    always_ff @(posedge clk) begin
        if (rst) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'hBEEF;
        end else if (os_strobe) begin
            lfsr1 <= {lfsr1[14:0], lfsr1[15] ^ lfsr1[13] ^ lfsr1[12] ^ lfsr1[10]};
            lfsr2 <= {lfsr2[14:0], lfsr2[15] ^ lfsr2[14] ^ lfsr2[12] ^ lfsr2[3]};
        end
    end

    // TPDF Dither: sum of two uniform random numbers (amplitude ~ 1 LSB in 16-bit scale)
    logic signed [9:0] dither_tpdf;
    assign dither_tpdf = $signed({2'b0, lfsr1[7:0]}) - $signed({2'b0, lfsr2[7:0]});

    // 5. Unconditionally Stable 1st-Order Error-Feedback Noise Shaping Filter:
    // v[n] = x[n] + e[n-1] + dither
    logic signed [17:0] err;
    (* IOB = "TRUE" *) logic [7:0] q_out_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            err       <= 18'sd0;
            q_out_reg <= 8'h80; // Mid-scale (128 = 0V AC)
        end else if (os_strobe) begin
            logic signed [17:0] v_sample;
            logic signed [17:0] next_err;

            // Compute noise-shaped sample with 1st-order error feedback and TPDF dither
            v_sample = $signed({2'b0, scaled_sample}) + err + $signed({{8{dither_tpdf[9]}}, dither_tpdf});

            // Quantize to 8-bit [0..255] with saturation
            if (v_sample < 18'sd0) begin
                q_out_reg <= 8'h00;
                next_err   = 18'sd0; // Reset error on clip to prevent integrator windup
            end else if (v_sample > 18'sd65280) begin // 255 << 8
                q_out_reg <= 8'hFF;
                next_err   = 18'sd0; // Reset error on clip to prevent integrator windup
            end else begin
                // Rounding: (v_sample + 128) >> 8
                logic [7:0] q_val;
                q_val     = (v_sample + 18'sd128) >>> 8;
                q_out_reg <= q_val;
                next_err  = v_sample - ($signed({10'b0, q_val}) <<< 8);
            end

            err <= next_err;
        end
    end

    assign dac_out = q_out_reg;

endmodule
