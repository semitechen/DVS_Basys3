`timescale 1ns / 1ps

/*
 * Module: dvs_uart_receiver
 * Author: Tomasz Jachymiak (Enhanced with Watchdog & Standalone Fallback)
 * Description: Decodes serial speed/direction packets from Board A.
 *              Automatically falls back to 1.0x Forward playback if Board A is disconnected.
 */

module dvs_uart_receiver (
    input  logic        clk,
    input  logic        rst,
    input  logic        rx_pin,
    
    // Zdekodowane sygnały dla silnika NCO
    output logic        ext_direction,
    output logic [15:0] ext_speed_factor
);

    logic       rx_done;
    logic [7:0] rx_data;

    // 1. Instancja warstwy fizycznej UART RX
    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115_200)
    ) rx_unit (
        .clk(clk),
        .rst(rst),
        .rx_pin(rx_pin),
        .data_out(rx_data),
        .rx_done(rx_done)
    );

    // 2. Maszyna stanów dekodująca ramkę DVS [SYNC 0xAA, DIR, SPEED_H, SPEED_L]
    typedef enum logic [1:0] {WAIT_SYNC, GET_DIR, GET_SPEED_H, GET_SPEED_L} state_t;
    state_t state, next_state;
    
    logic        dir_reg, next_dir;
    logic [15:0] speed_reg, next_speed;
    logic [7:0]  temp_dir;
    logic [7:0]  temp_speed_h;

    // Watchdog timer (50 ms timeout @ 100 MHz): Wraca do 1.0x FWD jeśli brak pakietów
    localparam logic [22:0] WATCHDOG_LIMIT = 23'd5_000_000; // 50 ms
    logic [22:0] watchdog_cnt;
    logic        packet_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            state           <= WAIT_SYNC;
            dir_reg         <= 1'b1;          // Domyślnie FWD (1.0x)
            speed_reg       <= 16'h1000;      // Domyślnie 1.0x (normalna prędkość)
            watchdog_cnt    <= 23'd0;
            temp_dir        <= 8'd1;
            temp_speed_h    <= 8'h10;
        end else begin
            state <= next_state;

            // Obsługa watchdoga
            if (packet_valid) begin
                watchdog_cnt <= 23'd0;
                dir_reg      <= next_dir;
                speed_reg    <= next_speed;
            end else if (watchdog_cnt < WATCHDOG_LIMIT) begin
                watchdog_cnt <= watchdog_cnt + 23'd1;
            end else begin
                // Brak pakietów od Płytki A (odłączona) -> Wymuś 1.0x FWD
                dir_reg   <= 1'b1;
                speed_reg <= 16'h1000;
            end

            // Buforowanie tymczasowych bajtów w trakcie odbioru ramki
            if (rx_done) begin
                if (state == GET_DIR)     temp_dir     <= rx_data;
                if (state == GET_SPEED_H) temp_speed_h <= rx_data;
            end
        end
    end

    always_comb begin
        next_state   = state;
        next_dir     = dir_reg;
        next_speed   = speed_reg;
        packet_valid = 1'b0;

        if (rx_done) begin
            case (state)
                WAIT_SYNC: begin
                    if (rx_data == 8'hAA) begin
                        next_state = GET_DIR;
                    end
                end
                
                GET_DIR: begin
                    next_state = GET_SPEED_H;
                end
                
                GET_SPEED_H: begin
                    next_state = GET_SPEED_L;
                end
                
                GET_SPEED_L: begin
                    next_dir     = temp_dir[0];
                    next_speed   = {temp_speed_h, rx_data};
                    packet_valid = 1'b1;
                    next_state   = WAIT_SYNC;
                end
            endcase
        end
    end

    assign ext_direction    = dir_reg;
    assign ext_speed_factor = speed_reg;

endmodule