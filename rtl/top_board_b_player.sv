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

    // Zewnętrzny przetwornik DAC (Pmod JB)
    output logic [7:0] dac,

    // Wejście z Płytki A (UART)
    input  logic uart_rx_pin,

    // Diody diagnostyczne
    output logic [15:0] led
);

    // --- Sygnały sterujące komunikacją (Tymczasowe, czekają na moduł UART) ---
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

    track_selector #(.MAX_TRACKS(4)) track_sel (
        .clk(clk), .rst(rst),
        .btn_up_pulse(btn_up_pulse),
        .btn_down_pulse(btn_down_pulse),
        .start_addr(current_track_addr),
        .play_req(track_play_req)
    );

    // --- 2. System Karty SD i Buforowania ---
    logic sd_ready, out_valid, rd_req;
    logic [7:0] out_byte;
    logic [31:0] rd_addr;
    
    sd_card_controller sd_ctrl (
        .clk(clk), .rst(rst),
        .rd_req(rd_req), .rd_addr(rd_addr),
        .sd_ready(sd_ready), .out_byte(out_byte), .out_valid(out_valid),
        .sd_cs(sd_cs), .sd_sck(sd_sck), .sd_mosi(sd_mosi), .sd_miso(sd_miso)
    );

    logic fifo_prog_full, fifo_empty, fifo_wr_en, fifo_rd_en;
    logic [7:0] fifo_wr_data, fifo_rd_data;

    sd_bram_bridge bridge (
        .clk(clk), .rst(rst),
        .play_req(track_play_req),
        .start_addr(current_track_addr),
        .direction(ext_direction), // Wpięte sterowanie kierunkiem!
        .sd_ready(sd_ready),
        .out_byte(out_byte), .out_valid(out_valid),
        .rd_req(rd_req), .rd_addr(rd_addr),
        .prog_full(fifo_prog_full),
        .wr_en(fifo_wr_en), .wr_data(fifo_wr_data)
    );

    audio_fifo fifo (
        .clk(clk), .rst(rst),
        .wr_en(fifo_wr_en), .wr_data(fifo_wr_data),
        .rd_en(fifo_rd_en), .rd_data(fifo_rd_data),
        .prog_full(fifo_prog_full), // Moduł mostka czeka na ten sygnał
        .empty(fifo_empty), .full() 
    );

    // --- 3. Silnik Zmiennej Prędkości (NCO) ---
    variable_speed_player v_player (
        .clk(clk), .rst(rst),
        .fifo_rd_data(fifo_rd_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .speed_factor(ext_speed_factor), // Wpięte sterowanie prędkością (Pitch)!
        .dac(dac)
    );

    // --- 4. Diagnostyka (Heartbeat) ---
    logic [26:0] heartbeat;
    always_ff @(posedge clk) heartbeat <= heartbeat + 1;
    assign led[15] = heartbeat[26];
    assign led[11] = sd_ready;
    assign led[8]  = fifo_empty;
    assign led[0]  = uart_rx_pin; // Podgląd sygnału UART

endmodule