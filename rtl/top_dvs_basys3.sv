`timescale 1ns / 1ps
/**
 * Module: top_dvs_basys3
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: Top-level module for the DVS system.
 *              Integrates XADC for timecode signal acquisition.
 */

module top_dvs_basys3 (
    // System Clock and Reset
    input  logic clk,
    input  logic rst,

    // User Interface (Buttons)
    input  logic btn_up,
    input  logic btn_down,

    // SD Card SPI Interface (Pmod JA - top row)
    output logic sd_cs,
    output logic sd_mosi,
    input  logic sd_miso,
    output logic sd_sck,

    // 8-bit R-2R DAC output (Pmod JA bottom row + JXADC)
    output logic [7:0] dac,

    // XADC Analog Auxiliary Inputs (JXADC Header)
    input  logic vauxp6,    // Channel 6 - Left P
    input  logic vauxn6,    // Channel 6 - Left N
    input  logic vauxp14,   // Channel 14 - Right P
    input  logic vauxn14,   // Channel 14 - Right N

    // Board LEDs
    output logic [15:0] led
);

   
    // SD Card & Audio Buffer (Feature Branch) 

    
    // SD Controller <-> BRAM Bridge
    logic        sd_rd_req;
    logic [31:0] sd_rd_addr;
    logic        sd_ready;
    logic [7:0]  sd_out_byte;
    logic        sd_out_valid;

    // BRAM Bridge <-> Audio FIFO
    logic        fifo_prog_empty;
    logic        fifo_empty;       
    logic        fifo_wr_en;
    logic [7:0]  fifo_wr_data;
    
    // Audio FIFO <-> DAC Player 
    logic        fifo_rd_en;
    logic [7:0]  fifo_rd_data; 

    // Auto-play logic
    logic prev_sd_ready = 0;
    logic auto_play_req;

    // Debouncing module
    logic btn_up_pulse;
    logic btn_down_pulse;
    
    always_ff @(posedge clk) begin
        if (rst) prev_sd_ready <= 0;
        else     prev_sd_ready <= sd_ready;
    end
    
    assign auto_play_req = (sd_ready && !prev_sd_ready);

    sd_card_controller sd_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .rd_req(sd_rd_req),
        .rd_addr(sd_rd_addr),
        .sd_ready(sd_ready),
        .out_byte(sd_out_byte),
        .out_valid(sd_out_valid),
        .sd_cs(sd_cs),
        .sd_sck(sd_sck),
        .sd_mosi(sd_mosi),
        .sd_miso(sd_miso)
    );

    sd_bram_bridge bridge_inst (
        .clk(clk),
        .rst(rst),
        .play_req(auto_play_req),
        .start_addr(32'd0), 
        .sd_ready(sd_ready),
        .out_byte(sd_out_byte),
        .out_valid(sd_out_valid),
        .rd_req(sd_rd_req),
        .rd_addr(sd_rd_addr),
        .prog_empty(fifo_prog_empty),
        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data)
    );

    audio_fifo fifo_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data),
        .rd_en(fifo_rd_en),
        .rd_data(fifo_rd_data),
        .prog_empty(fifo_prog_empty), 
        .empty(fifo_empty),        
        .full()
    );

    // Temporary DAC outputs
    dac_player player_inst (
        .clk(clk),
        .rst(rst),
        .fifo_rd_data(fifo_rd_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .dac(dac)
    );

    button_debouncer #(
    .CYCLES(1_000_000)
    ) deb_up (
    .clk(clk),
    .rst(rst),
    .btn_in(btn_up),
    .btn_out_state(),          // Zostawiamy puste, jeśli nie potrzebujemy poziomu
    .btn_out_pulse(btn_up_pulse) // Pobieramy tylko czysty impuls
    );
    
    button_debouncer #(
    .CYCLES(1_000_000)
) deb_down (
    .clk(clk),
    .rst(rst),
    .btn_in(btn_down),
    .btn_out_state(),              
    .btn_out_pulse(btn_down_pulse)
);

    
    // -Internal Signals (DVS Timecode from Main Branch)
    
    
    logic [11:0] adc_data_l;
    logic [11:0] adc_data_r;
    logic        adc_data_valid;

    logic [15:0] filtered_data_l;
    logic [15:0] filtered_data_r;

    logic [31:0] tc_period;
    logic        tc_period_valid;
    logic        tc_direction;


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

    // --- 3. Speed Detection ---
    timecode_speed_detector speed_det (
        .clk(clk),
        .rst(rst),
        .signal_in(filtered_data_l),
        .signal_valid(adc_data_valid),
        .period_out(tc_period),
        .period_valid(tc_period_valid)
    );

    // --- 4. Direction Detection ---
    timecode_direction_detector dir_det (
        .clk(clk),
        .rst(rst),
        .signal_l(filtered_data_l),
        .signal_r(filtered_data_r),
        .signal_valid(adc_data_valid),
        .direction(tc_direction)
    );

    // --- 5. Diagnostic Logic (Heartbeat & VU Meter) ---
    logic [26:0] heartbeat_cnt;
    always_ff @(posedge clk) begin
        if (rst) heartbeat_cnt <= 0;
        else     heartbeat_cnt <= heartbeat_cnt + 1;
    end

    assign led[15]   = heartbeat_cnt[26]; // Heartbeat blinker (~0.7Hz)
    assign led[14]   = tc_direction;      // Direction indicator (1=Fwd, 0=Bwd)
    assign led[13:0] = tc_period[19:6];   // Show portion of the period (speed)

endmodule
