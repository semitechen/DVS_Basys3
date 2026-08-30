`timescale 1ns / 1ps

module top_board_b_player (
    input  logic clk,
    input  logic rst,

    // Przyciski do wyboru utworów
    input  logic btn_up,
    input  logic btn_down,

    // Karta SD (Pmod JA)
    output logic sd_cs,
    output logic sd_mosi,
    input  logic sd_miso,
    output logic sd_sck,

    // Zewnętrzny przetwornik DAC (Pmod JA + JXADC)
    output logic [7:0] dac,

    // Wejście z Płytki A (UART)
    input  logic uart_rx_pin,

    // Diody diagnostyczne
    output logic [15:0] led
);

    // --- Sygnały sterujące komunikacją UART (DVS Control) ---
    logic [15:0] ext_speed_factor; // 16'h1000 = 1.0x
    logic        ext_direction;    // 1 = Fwd, 0 = Bwd
    
    dvs_uart_receiver dvs_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx_pin(uart_rx_pin),
        .ext_direction(ext_direction),
        .ext_speed_factor(ext_speed_factor)
    );

    // --- 1. Debouncery i Selektor Utworów ---
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

    // --- 2. System Karty SD i Buforowania ---
    logic sd_ready, out_valid, rd_req;
    logic [7:0] out_byte;
    logic [31:0] rd_addr;
    logic [3:0]  sd_ctrl_state;
    
    sd_card_controller sd_ctrl (
        .clk(clk), .rst(rst),
        .rd_req(rd_req), .rd_addr(rd_addr),
        .sd_ready(sd_ready), .out_byte(out_byte), .out_valid(out_valid),
        .sd_cs(sd_cs), .sd_sck(sd_sck), .sd_mosi(sd_mosi), .sd_miso(sd_miso),
        .ctrl_state(sd_ctrl_state)
    );

    logic fifo_prog_full, fifo_empty, fifo_wr_en, fifo_rd_en;
    logic [7:0] fifo_wr_data, fifo_rd_data;
    logic [2:0] bridge_state;
    logic       is_playing;

    sd_bram_bridge bridge (
        .clk(clk), .rst(rst),
        .play_req(track_play_req),
        .start_addr(current_track_addr),
        .direction(ext_direction),
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

    // --- 3. Silnik Zmiennej Prędkości (NCO) ---
    logic [7:0] raw_audio_sample;

    variable_speed_player v_player (
        .clk(clk), .rst(rst),
        .fifo_rd_data(fifo_rd_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .speed_factor(ext_speed_factor),
        .sample_out(raw_audio_sample)
    );

    // --- 4. Wysokiej Jakości Przetwornik DAC R-2R z Noise Shapingiem 16x ---
    r2r_dac #(
        .INPUT_WIDTH(8),
        .SIGNED_INPUT(1'b0) // 8-bit unsigned PCM [0..255]
    ) u_r2r_dac (
        .clk(clk),
        .rst(rst),
        .sample_in(raw_audio_sample),
        .dac_out(dac)
    );

    // --- 5. Diagnostyka (16-LED Real-Time Diagnostic Dashboard) ---
    logic [26:0] heartbeat;
    always_ff @(posedge clk) heartbeat <= heartbeat + 1;

    assign led[15]    = heartbeat[26];      // Heartbeat (~0.7 Hz)
    assign led[14:12] = bridge_state;       // Stan mostka SD-BRAM (0=IDLE, 1=WAIT_SD, 2=READ, 4=PUSH, 5=NEXT)
    assign led[11]    = sd_ready;           // Karta SD gotowa (1 = OK)
    assign led[10]    = is_playing;         // Tryb odtwarzania aktywny (1 = Play)
    assign led[9]     = fifo_prog_full;     // Bufor FIFO wypełniony (1 = Bufor pełny)
    assign led[8]     = fifo_empty;         // Bufor FIFO pusty (1 = Pusty, 0 = Są dane audio)
    assign led[7:4]   = sd_ctrl_state;      // Stan kontrolera SD (6=IDLE, 7=CMD17, 8=WAIT_TOK, 9=DATA)
    assign led[3:2]   = track_idx[1:0];     // Aktualnie wybrany numer utworu (0..3)
    assign led[1]     = ext_direction;      // Kierunek odtwarzania (1 = Fwd, 0 = Bwd)
    assign led[0]     = uart_rx_pin;        // Stan wejścia UART RX

endmodule