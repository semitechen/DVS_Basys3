`timescale 1ns / 1ps

module timecode_speed_detector (
    input  logic              clk,
    input  logic              rst,
    input  logic signed [15:0] signal_in,
    input  logic              signal_valid,
    output logic [31:0]       period_out,
    output logic              period_valid
);

    localparam signed [15:0] HYSTERESIS = 16'sd500;

    logic signed [15:0] signal_reg;
    logic               state; // 0 for negative, 1 for positive
    logic [31:0]        counter;

    always_ff @(posedge clk) begin
        if (rst) begin
            signal_reg   <= 0;
            state        <= 0;
            counter      <= 0;
            period_out   <= 0;
            period_valid <= 0;
        end else begin
            period_valid <= 0;
            counter      <= counter + 1;

            if (signal_valid) begin
                signal_reg <= signal_in;
                
                if (state == 0 && signal_in > HYSTERESIS) begin
                    state        <= 1;
                    period_out   <= counter;
                    period_valid <= 1;
                    counter      <= 0;
                end else if (state == 1 && signal_in < -HYSTERESIS) begin
                    state        <= 0;
                end
            end

            if (counter > 32'd10_000_000) begin
                period_out   <= 0;
                period_valid <= 1;
                counter      <= 0;
            end
        end
    end

endmodule
