`timescale 1ns / 1ps

module timecode_filter (
    input  logic        clk,
    input  logic        rst,
    input  logic [11:0] x_in,
    input  logic        x_valid,
    output logic [15:0] y_out
);

    logic signed [27:0] hpf_reg;
    logic signed [27:0] lpf_reg;
    
    logic signed [27:0] prev_x;
    logic signed [27:0] curr_x_shifted;

    always_ff @(posedge clk) begin
        if (rst) begin
            hpf_reg <= 0;
            lpf_reg <= 0;
            prev_x  <= 0;
            y_out   <= 0;
        end else if (x_valid) begin
            curr_x_shifted <= {12'b0, x_in, 4'b0};
            
            hpf_reg <= (curr_x_shifted - prev_x) + hpf_reg - (hpf_reg >>> 12);
            prev_x  <= curr_x_shifted;

            lpf_reg <= lpf_reg + ((hpf_reg - lpf_reg) >>> 6);
            
            y_out <= lpf_reg[19:4];
        end
    end

endmodule
