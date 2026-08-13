`timescale 1ns / 1ps
/**
 * Module: r2r_dac
 * Project: DVS_Basys3 (Digital Vinyl System)
 * Description: 8-bit R-2R Resistor Ladder DAC Driver.
 *              Converts audio samples (16-bit signed PCM or 8-bit unsigned PCM)
 *              into an 8-bit parallel output bus for an external R-2R DAC ladder.
 */

module r2r_dac #(
    parameter int INPUT_WIDTH = 16,
    parameter int DAC_WIDTH   = 8
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic [INPUT_WIDTH-1:0] din,     // Input audio sample (2's complement signed or unsigned)
    output logic [DAC_WIDTH-1:0]   dac_out  // 8-bit parallel R-2R output bus [dac7..dac0]
);

    logic [DAC_WIDTH-1:0] dac_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset to mid-scale (DC offset bias at VDD/2 ~ 1.65V)
            dac_reg <= {1'b1, {(DAC_WIDTH-1){1'b0}}};
        end else begin
            // Convert 16-bit signed 2's complement PCM to 8-bit unsigned offset binary
            // Inverting the MSB shifts range from [-32768..32767] to [0..255]
            dac_reg <= {~din[INPUT_WIDTH-1], din[INPUT_WIDTH-2 -: (DAC_WIDTH-1)]};
        end
    end

    assign dac_out = dac_reg;

endmodule
