`timescale 1ns / 1ps
/**
 * Module: top_dvs_basys3
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Production Top-Level Module for DVS Relative Mode Engine.
 *              Integrates XADC digitization and Quadrature Timecode Position Tracker.
 *              Outputs 32-bit Relative Sample Position @ 44.1 kHz audio sample rate.
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

    // Board LEDs
    output logic [15:0] led
);

    // --- Internal Signals ---
    logic [11:0] adc_data_l;
    logic [11:0] adc_data_r;
    logic        adc_data_valid;

    logic [31:0] sample_position;
    logic        direction_indicator;
    logic [15:0] position_leds;


    // --- Constant Assignments ---
    assign sd_cs   = 1'b1; 
    assign sd_mosi = 1'b0;
    assign sd_sck  = 1'b0;


    // --- 1. XADC Interface Instance ---
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


    // --- 2. Timecode Relative Mode Position Tracker Instance ---
    timecode_pos_tracker pos_tracker (
        .clk(clk),
        .rst(rst),
        .data_l(adc_data_l),
        .data_r(adc_data_r),
        .data_valid(adc_data_valid),
        .sample_pos(sample_position),
        .direction(direction_indicator),
        .led_display(position_leds)
    );


    // --- 3. System Heartbeat & LED Diagnostics ---
    logic [26:0] heartbeat_cnt;
    always_ff @(posedge clk) begin
        if (rst) heartbeat_cnt <= 0;
        else     heartbeat_cnt <= heartbeat_cnt + 1;
    end

    assign led[15]   = heartbeat_cnt[26];       // Heartbeat blinker (~0.7Hz)
    assign led[14]   = direction_indicator;      // 1 = Forward (33 1/3 RPM), 0 = Reverse
    assign led[13:0] = position_leds[13:0];     // Relative Mode position progress

endmodule
