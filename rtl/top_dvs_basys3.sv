`timescale 1ns / 1ps
/**
 * Module: top_dvs_basys3
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Top-level module for XADC and hardware verification.
 *              Provides real-time monitoring of stereo timecode signals
 *              via LEDs (VU Meter) and UART (CSV format).
 */

module top_dvs_basys3 (
    // System Clock and Reset
    input  logic clk,
    input  logic rst,

    // User Interface (Buttons)
    input  logic btn_up,
    input  logic btn_down,

    // SD Card SPI Interface
    output logic sd_cs,
    output logic sd_mosi,
    input  logic sd_miso,
    output logic sd_sck,

    // XADC Analog Auxiliary Inputs (JXADC Header)
    input  logic vauxp6,    // Channel 6 - Left P
    input  logic vauxn6,    // Channel 6 - Left N
    input  logic vauxp14,   // Channel 14 - Right P
    input  logic vauxn14,   // Channel 14 - Right N

    // USB-UART Bridge
    output logic uart_tx_pin,

    // Board LEDs
    output logic [15:0] led
);

    // --- Internal Signals ---
    logic [11:0] adc_data_l;
    logic [11:0] adc_data_r;
    logic        adc_data_valid;

    logic [7:0]  uart_data;
    logic        uart_start;
    logic        uart_busy;
    logic        uart_done_gate;

    // --- Constant Assignments ---
    assign sd_cs   = 1'b1; // Disable SD card for now
    assign sd_mosi = 1'b0;
    assign sd_sck  = 1'b0;


    // --- 1. XADC Interface Instance ---
    // Samples VAUX6 and VAUX14 in Continuous Sequence Mode
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


    // --- 2. UART Transmitter Instance ---
    // Configured for 115200 Baud @ 100MHz
    uart_tx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115_200)
    ) debug_uart (
        .clk(clk),
        .rst(rst),
        .data_in(uart_data),
        .tx_start(uart_start),
        .tx_pin(uart_tx_pin),
        .tx_busy(uart_busy)
    );


    // --- 3. Diagnostic Logic (Heartbeat & VU Meter) ---
    logic [26:0] heartbeat_cnt;
    always_ff @(posedge clk) begin
        if (rst) heartbeat_cnt <= 0;
        else     heartbeat_cnt <= heartbeat_cnt + 1;
    end

    assign led[15]   = heartbeat_cnt[26]; // Heartbeat blinker (~0.7Hz)
    assign led[7:0]  = adc_data_l[11:4];  // Left Channel Intensity
    assign led[14:8] = adc_data_r[11:5];  // Right Channel Intensity


    // --- 4. UART Monitoring State Machine ---
    // Transmits ADC values in CSV format (LL,RR\r\n) at 10Hz
    function [7:0] to_hex(input [3:0] nibble);
        if (nibble < 4'd10) return 8'h30 + nibble;
        else                return 8'h37 + nibble;
    endfunction

    logic [23:0] sample_timer;
    logic [3:0]  tx_step;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            sample_timer <= 0;
            tx_step <= 0;
            uart_start <= 1'b0;
            uart_done_gate <= 1'b1;
        end else begin
            uart_start <= 1'b0;

            if (sample_timer < 24'd10_000_000) begin
                sample_timer <= sample_timer + 1;
                tx_step <= 0;
                uart_done_gate <= 1'b1;
            end else if (!uart_busy && uart_done_gate) begin
                uart_done_gate <= 1'b0;
                case (tx_step)
                    4'd0: begin uart_data <= to_hex(adc_data_l[11:8]); uart_start <= 1'b1; tx_step <= 4'd1; end
                    4'd1: begin uart_data <= to_hex(adc_data_l[7:4]);  uart_start <= 1'b1; tx_step <= 4'd2; end
                    4'd2: begin uart_data <= 8'h2C; uart_start <= 1'b1; tx_step <= 4'd3; end // ','
                    4'd3: begin uart_data <= to_hex(adc_data_r[11:8]); uart_start <= 1'b1; tx_step <= 4'd4; end
                    4'd4: begin uart_data <= to_hex(adc_data_r[7:4]);  uart_start <= 1'b1; tx_step <= 4'd5; end
                    4'd5: begin uart_data <= 8'h0D; uart_start <= 1'b1; tx_step <= 4'd6; end // '\r'
                    4'd6: begin uart_data <= 8'h0A; uart_start <= 1'b1; tx_step <= 4'd7; end // '\n'
                    4'd7: begin sample_timer <= 0; end
                    default: tx_step <= 4'd0;
                endcase
            end else if (uart_busy) begin
                uart_done_gate <= 1'b1;
            end
        end
    end

endmodule
