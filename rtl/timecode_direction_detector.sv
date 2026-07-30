`timescale 1ns / 1ps

module timecode_direction_detector (
    input  logic              clk,
    input  logic              rst,
    input  logic signed [15:0] signal_l,
    input  logic signed [15:0] signal_r,
    input  logic              signal_valid,
    output logic              direction // 1 for Forward, 0 for Backward
);

    localparam signed [15:0] HYSTERESIS = 16'sd500;
    localparam int CONFIDENCE_MAX = 15;

    logic state_l, state_r;
    logic prev_state_l;
    
    logic signed [4:0] confidence_cnt;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_l        <= 0;
            state_r        <= 0;
            prev_state_l   <= 0;
            confidence_cnt <= 0;
            direction      <= 1;
        end else if (signal_valid) begin
            prev_state_l <= state_l;

            if (state_l == 0 && signal_l > HYSTERESIS)       state_l <= 1;
            else if (state_l == 1 && signal_l < -HYSTERESIS) state_l <= 0;

            if (state_r == 0 && signal_r > HYSTERESIS)       state_r <= 1;
            else if (state_r == 1 && signal_r < -HYSTERESIS) state_r <= 0;

            if (state_l && !prev_state_l) begin
                if (state_r == 0) begin
                    if (confidence_cnt < CONFIDENCE_MAX) confidence_cnt <= confidence_cnt + 1;
                end else begin
                    if (confidence_cnt > -CONFIDENCE_MAX) confidence_cnt <= confidence_cnt - 1;
                end
            end

            if (confidence_cnt > 5)       direction <= 1;
            else if (confidence_cnt < -5) direction <= 0;
        end
    end

endmodule
