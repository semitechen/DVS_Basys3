`timescale 1ns / 1ps
/**
 * Module: top_dvs_basys3
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Production Integrated Top-Level System for DVS Turntable Timecode
 *              and High-Fidelity SD Card Audio Player.
 *
 * System Architecture:
 *  - XADC Analog Frontend: Digitizes Serato 1 kHz Quadrature Timecode from Turntable.
 *  - 4x Quadrature Decoder: Tracks sample position, direction, and Q4.12 real-time speed.
 *  - High-Speed SD Card Engine: 16.67 MHz SPI controller with BRAM double-buffering.
 *  - NCO Variable Speed Audio Player: Streams 44.1 kHz PCM modulated by timecode.
 *  - 16x Oversampled Noise-Shaped DAC: 8-bit R-2R ladder output with TPDF dither.
 *  - Mode Switch (sw[0]):
 *      sw[0] = 1 -> DVS Mode (turntable timecode controls audio speed & platter LEDs).
 *      sw[0] = 0 -> Standalone Mode (fixed 1.0x auto-play & diagnostic dashboard LEDs).
 */

module top_dvs_basys3 (
    input  logic        clk,
    input  logic        rst,

    // Switch wyboru trybu: sw[0] = 1 (DVS Vinyl Mode), sw[0] = 0 (Standalone Auto-Play)
    input  logic [0:0]  sw,

    // Przyciski zmiany utworów
    input  logic        btn_up,
    input  logic        btn_down,

    // Karta SD (Pmod JA górny rząd)
    output logic        sd_cs,
    output logic        sd_mosi,
    input  logic        sd_miso,
    output logic        sd_sck,

    // 8-bitowy przetwornik DAC R-2R (Pmod JA dolny rząd + JXADC)
    output logic [7:0]  dac,

    // Wejścia analogowe XADC z gramofonu (Pmod JXADC)
    input  logic        vauxp6,    // Lewy kanał timecode (+)
    input  logic        vauxn6,    // Lewy kanał timecode (-)
    input  logic        vauxp14,   // Prawy kanał timecode (+)
    input  logic        vauxn14,   // Prawy kanał timecode (-)

    // Opcjonalne wejście UART z Płytki A (Pmod JC1)
    input  logic        uart_rx_pin,

    // 16 Diod LED (Wskaźnik pozycji winyla w trybie DVS lub Dashboard diagnostyczny)
    output logic [15:0] led
);

    // =========================================================================
    // 1. XADC Analog Digitization Interface
    // =========================================================================
    logic [11:0] adc_data_l;
    logic [11:0] adc_data_r;
    logic        adc_data_valid;

    xadc_interface xadc_inst (
        .clk(clk),
        .rst(rst),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .data_l(adc_data_l),
        .data_r(adc_data_r),
        .data_valid(adc_data_valid)
    );


    // =========================================================================
    // 2. DVS Timecode Position, Direction & Speed Tracker
    // =========================================================================
    logic [31:0] dvs_sample_pos;
    logic        dvs_direction;
    logic [15:0] dvs_speed_factor;
    logic        dvs_signal_present;

    timecode_pos_tracker #(
        .HYSTERESIS(13'sd60),
        .SQUELCH_THRESHOLD(16'd120)
    ) pos_tracker (
        .clk(clk),
        .rst(rst),
        .data_l(adc_data_l),
        .data_r(adc_data_r),
        .data_valid(adc_data_valid),
        .sample_pos(dvs_sample_pos),
        .direction(dvs_direction),
        .speed_factor(dvs_speed_factor),
        .signal_present_out(dvs_signal_present)
    );

    // 16-LED Visual Vinyl Platter Display
    logic [15:0] dvs_platter_leds;
    led_pos_display led_display_inst (
        .clk(clk),
        .rst(rst),
        .sample_pos(dvs_sample_pos),
        .led(dvs_platter_leds)
    );


    // =========================================================================
    // 3. Fallback UART Receiver (Board A Link)
    // =========================================================================
    logic [15:0] uart_speed_factor;
    logic        uart_direction;

    dvs_uart_receiver dvs_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx_pin(uart_rx_pin),
        .ext_direction(uart_direction),
        .ext_speed_factor(uart_speed_factor)
    );


    // =========================================================================
    // 4. Track Selection & Debouncing
    // =========================================================================
    logic btn_up_pulse, btn_down_pulse;

    button_debouncer #(.CYCLES(1_000_000)) deb_up (
        .clk(clk), .rst(rst), .btn_in(btn_up),
        .btn_out_state(), .btn_out_pulse(btn_up_pulse)
    );

    button_debouncer #(.CYCLES(1_000_000)) deb_down (
        .clk(clk), .rst(rst), .btn_in(btn_down),
        .btn_out_state(), .btn_out_pulse(btn_down_pulse)
    );

    logic [31:0] current_track_addr;
    logic        track_play_req;
    logic [7:0]  track_idx;

    track_selector #(.MAX_TRACKS(4)) track_sel (
        .clk(clk), .rst(rst),
        .btn_up_pulse(btn_up_pulse),
        .btn_down_pulse(btn_down_pulse),
        .start_addr(current_track_addr),
        .play_req(track_play_req),
        .current_track_idx(track_idx)
    );


    // =========================================================================
    // 5. Dynamic Speed & Direction Multiplexer
    // =========================================================================
    logic [15:0] active_speed_factor;
    logic        active_direction;

    always_comb begin
        if (sw[0]) begin
            // DVS Vinyl Mode: sterowanie bezpośrednio z gramofonu (XADC)
            active_speed_factor = dvs_speed_factor;
            active_direction    = dvs_direction;
        end else begin
            // Standalone Mode: stała prędkość 1.0x (lub UART, z watchdiogiem 1.0x)
            active_speed_factor = uart_speed_factor;
            active_direction    = uart_direction;
        end
    end


    // =========================================================================
    // 6. High-Speed SD Card Controller & BRAM Streaming Bridge
    // =========================================================================
    logic        sd_ready, out_valid, rd_req;
    logic [7:0]  out_byte;
    logic [31:0] rd_addr;
    logic [3:0]  sd_ctrl_state;

    sd_card_controller sd_ctrl (
        .clk(clk), .rst(rst),
        .rd_req(rd_req), .rd_addr(rd_addr),
        .sd_ready(sd_ready), .out_byte(out_byte), .out_valid(out_valid),
        .sd_cs(sd_cs), .sd_sck(sd_sck), .sd_mosi(sd_mosi), .sd_miso(sd_miso),
        .ctrl_state(sd_ctrl_state)
    );

    logic       fifo_prog_full, fifo_empty, fifo_wr_en, fifo_rd_en;
    logic [7:0] fifo_wr_data, fifo_rd_data;
    logic [2:0] bridge_state;
    logic       is_playing;

    sd_bram_bridge bridge (
        .clk(clk), .rst(rst),
        .play_req(track_play_req),
        .start_addr(current_track_addr),
        .direction(active_direction),
        .sd_ready(sd_ready),
        .out_byte(out_byte), .out_valid(out_valid),
        .rd_req(rd_req), .rd_addr(rd_addr),
        .prog_full(fifo_prog_full),
        .wr_en(fifo_wr_en), .wr_data(fifo_wr_data),
        .bridge_state(bridge_state),
        .is_playing(is_playing)
    );

    audio_fifo fifo (
        .clk(clk), .rst(rst),
        .wr_en(fifo_wr_en), .wr_data(fifo_wr_data),
        .rd_en(fifo_rd_en), .rd_data(fifo_rd_data),
        .prog_full(fifo_prog_full),
        .empty(fifo_empty), .full()
    );


    // =========================================================================
    // 7. NCO Variable Speed Audio Player
    // =========================================================================
    logic [7:0] raw_audio_sample;

    variable_speed_player v_player (
        .clk(clk), .rst(rst),
        .fifo_rd_data(fifo_rd_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .speed_factor(active_speed_factor),
        .sample_out(raw_audio_sample)
    );


    // =========================================================================
    // 8. 16x Oversampled Noise-Shaped R-2R Audio DAC
    // =========================================================================
    r2r_dac #(
        .INPUT_WIDTH(8),
        .SIGNED_INPUT(1'b0)
    ) u_r2r_dac (
        .clk(clk),
        .rst(rst),
        .sample_in(raw_audio_sample),
        .dac_out(dac)
    );


    // =========================================================================
    // 9. Diagnostic & Visual Display LEDs
    // =========================================================================
    logic [25:0] heartbeat_cnt;
    always_ff @(posedge clk) begin
        if (rst) heartbeat_cnt <= 26'd0;
        else     heartbeat_cnt <= heartbeat_cnt + 26'd1;
    end

    // Dashboard diagnostyczny dla trybu Standalone
    logic [15:0] diag_dashboard_leds;
    assign diag_dashboard_leds = {
        heartbeat_cnt[25],              // [15] Heartbeat (~1.5 Hz)
        active_direction,               // [14] Direction (1 = FWD, 0 = BWD)
        dvs_signal_present,             // [13] Timecode signal present
        sd_ready,                       // [12] SD Card Ready
        is_playing,                     // [11] Bridge Active Playing
        fifo_prog_full,                 // [10] FIFO Programmed Full
        fifo_empty,                     // [9]  FIFO Underflow Warning
        sw[0],                          // [8]  Active Mode (1 = DVS, 0 = Auto)
        track_idx[3:0],                 // [7:4] Selected Track ID
        sd_ctrl_state[3:0]              // [3:0] SD Card Controller FSM State
    };

    // Przełączanie wizualizacji na diodach LED w zależności od trybu
    assign led = sw[0] ? dvs_platter_leds : diag_dashboard_leds;

endmodule
