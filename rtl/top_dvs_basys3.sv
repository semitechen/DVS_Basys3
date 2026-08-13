`timescale 1ns / 1ps
/**
 * Module: top_dvs_basys3
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Top-level module for the DVS system.
 *              Integrates XADC, DSP Filters, and 8-bit R-2R DAC Audio Output.
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
    output logic [15:0] led,

    // 8-Bit R-2R Resistor Ladder DAC Output Bus [dac7..dac0]
    output logic [7:0]  dac
);

    // --- Internal Signals ---
    logic [11:0] adc_data_l;
    logic [11:0] adc_data_r;
    logic        adc_data_valid;

    logic [15:0] filtered_data_l;
    logic [15:0] filtered_data_r;

    logic [31:0] tc_period;
    logic        tc_period_valid;
    logic        tc_direction;


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

    // --- 2. Filter Instances ---
    timecode_filter filter_l (
        .clk(clk),
        .rst(rst),
        .x_in(adc_data_l),
        .x_valid(adc_data_valid),
        .y_out(filtered_data_l)
    );

    timecode_filter filter_r (
        .clk(clk),
        .rst(rst),
        .x_in(adc_data_r),
        .x_valid(adc_data_valid),
        .y_out(filtered_data_r)
    );

    // --- 3. Speed & Direction Detection ---
    timecode_speed_detector speed_det (
        .clk(clk),
        .rst(rst),
        .signal_in(filtered_data_l),
        .signal_valid(adc_data_valid),
        .period_out(tc_period),
        .period_valid(tc_period_valid)
    );

    timecode_direction_detector dir_det (
        .clk(clk),
        .rst(rst),
        .signal_l(filtered_data_l),
        .signal_r(filtered_data_r),
        .signal_valid(adc_data_valid),
        .direction(tc_direction)
    );


    // --- 4. 8-Bit R-2R Resistor Ladder DAC Instance ---
    r2r_dac #(
        .INPUT_WIDTH(16),
        .DAC_WIDTH(8)
    ) dac_inst (
        .clk(clk),
        .rst(rst),
        .din(filtered_data_l),
        .dac_out(dac)
    );


    // --- 5. Diagnostic Logic (Heartbeat, VU Meter & DAC Level) ---
    logic [26:0] heartbeat_cnt;
    always_ff @(posedge clk) begin
        if (rst) heartbeat_cnt <= 0;
        else     heartbeat_cnt <= heartbeat_cnt + 1;
    end

    assign led[15]   = heartbeat_cnt[26];    // Heartbeat blinker (~0.7Hz)
    assign led[14]   = tc_direction;         // Direction indicator (1=Fwd, 0=Bwd)
    assign led[13:8] = tc_period[11:6];   // Speed period monitor
    assign led[7:0]  = dac;                  // Real-time 8-bit DAC output level

endmodule
