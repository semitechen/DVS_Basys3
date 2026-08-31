`timescale 1ns / 1ps
/**
 * Module: top_board_b_dac
 * Project: DVS_Basys3 (Digital Vinyl System) - Board B
 * Description: Real-Time UART Audio Receiver & 16x Noise-Shaped R-2R DAC Output Engine.
 *
 * Board B Architecture:
 *  - High-Speed UART Receiver: Receives 8-bit audio PCM @ 2,000,000 baud from Board A via Pmod JC1.
 *  - Audio Watchdog: Automatically silences DAC to analog midpoint (0x80) on cable disconnect.
 *  - 16x Oversampled Noise-Shaped DAC: 8-bit physical R-2R ladder output with TPDF dither and headroom scaling.
 *  - 16-LED VU Meter: Displays live audio waveform dynamics, peak amplitude, and UART stream health.
 */

module top_board_b_dac (
    input  logic        clk,
    input  logic        rst,

    // Wejście UART Audio Stream z Płytki A (Pmod JC1 - pin K17)
    input  logic        uart_rx_pin,

    // 8-bitowy przetwornik DAC R-2R (Pmod JA dolny rząd + JXADC)
    output logic [7:0]  dac,

    // 16 Diod LED (Miernik wysterowania VU Meter + Status odbioru)
    output logic [15:0] led
);

    // =========================================================================
    // 1. High-Speed 2 Mbps UART Audio Receiver
    // =========================================================================
    logic [7:0] rx_byte;
    logic       rx_valid;

    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(2_000_000)
    ) audio_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx_pin(uart_rx_pin),
        .data_out(rx_byte),
        .rx_done(rx_valid)
    );


    // =========================================================================
    // 2. Audio Sample Latch & Watchdog Silence (200 ms Timeout)
    // =========================================================================
    localparam logic [24:0] WATCHDOG_LIMIT = 25'd20_000_000; // 200 ms @ 100 MHz

    logic [7:0]  active_audio_sample;
    logic [24:0] watchdog_cnt;
    logic        uart_active;

    always_ff @(posedge clk) begin
        if (rst) begin
            active_audio_sample <= 8'd128; // Analogowa cisza (środek skali 1.65V)
            watchdog_cnt        <= 25'd0;
            uart_active         <= 1'b0;
        end else begin
            if (rx_valid) begin
                active_audio_sample <= rx_byte;
                watchdog_cnt        <= 25'd0;
                uart_active         <= 1'b1;
            end else if (watchdog_cnt < WATCHDOG_LIMIT) begin
                watchdog_cnt <= watchdog_cnt + 25'd1;
            end else begin
                // Brak pakietów audio przez 200 ms -> Wycisz DAC do zera AC
                active_audio_sample <= 8'd128;
                uart_active         <= 1'b0;
            end
        end
    end


    // =========================================================================
    // 3. 16x Oversampled Noise-Shaped R-2R Audio DAC
    // =========================================================================
    r2r_dac #(
        .INPUT_WIDTH(8),
        .SIGNED_INPUT(1'b0)
    ) u_r2r_dac (
        .clk(clk),
        .rst(rst),
        .sample_in(active_audio_sample),
        .dac_out(dac)
    );


    // =========================================================================
    // 4. Live Audio VU Meter & Diagnostic LEDs
    // =========================================================================
    logic [25:0] heartbeat_cnt;
    always_ff @(posedge clk) begin
        if (rst) heartbeat_cnt <= 26'd0;
        else     heartbeat_cnt <= heartbeat_cnt + 26'd1;
    end

    // Obliczanie amplitudy sygnału audio od środka skali (0..127)
    logic [6:0] audio_magnitude;
    always_comb begin
        if (active_audio_sample >= 8'd128) begin
            audio_magnitude = active_audio_sample[6:0];
        end else begin
            audio_magnitude = 7'd128 - active_audio_sample[6:0];
        end
    end

    // Skalowanie amplitudy na 12-diodowy bargraph VU Meter
    logic [11:0] vu_meter;
    always_comb begin
        if      (audio_magnitude >= 7'd96) vu_meter = 12'b1111_1111_1111;
        else if (audio_magnitude >= 7'd80) vu_meter = 12'b0111_1111_1111;
        else if (audio_magnitude >= 7'd64) vu_meter = 12'b0011_1111_1111;
        else if (audio_magnitude >= 7'd48) vu_meter = 12'b0001_1111_1111;
        else if (audio_magnitude >= 7'd36) vu_meter = 12'b0000_1111_1111;
        else if (audio_magnitude >= 7'd28) vu_meter = 12'b0000_0111_1111;
        else if (audio_magnitude >= 7'd20) vu_meter = 12'b0000_0011_1111;
        else if (audio_magnitude >= 7'd14) vu_meter = 12'b0000_0001_1111;
        else if (audio_magnitude >= 7'd10) vu_meter = 12'b0000_0000_1111;
        else if (audio_magnitude >= 7'd6)  vu_meter = 12'b0000_0000_0111;
        else if (audio_magnitude >= 7'd3)  vu_meter = 12'b0000_0000_0011;
        else if (audio_magnitude >= 7'd1)  vu_meter = 12'b0000_0000_0001;
        else                               vu_meter = 12'b0000_0000_0000;
    end

    // [15] Heartbeat Blinker (~1.5 Hz)
    // [14] UART Link Active Indicator
    // [13:12] Upper Status LEDs
    // [11:0] Dynamic Audio VU Meter Bargraph
    assign led = {
        heartbeat_cnt[25],              // [15] Heartbeat
        uart_active,                    // [14] UART Active link
        watchdog_cnt[19],               // [13] UART RX Byte Pulse toggle
        1'b0,                           // [12] Spacer
        vu_meter                        // [11:0] 12-LED Audio VU Meter
    };

endmodule
