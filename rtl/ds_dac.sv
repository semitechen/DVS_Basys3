`timescale 1ns / 1ps

module ds_dac #(
    parameter int WIDTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] din,
    output logic             dout
);

    localparam logic [WIDTH+1:0] BIAS = {2'b01, {(WIDTH){1'b0}}};

    logic [WIDTH+1:0] sigma_1, sigma_2;
    logic [WIDTH+1:0] delta_1, delta_2;
    logic [WIDTH+1:0] feedback;

    always_ff @(posedge clk) begin
        if (rst) begin
            sigma_1  <= BIAS;
            sigma_2  <= BIAS;
            dout     <= 1'b0;
        end else begin
            sigma_1 <= delta_1 + sigma_1;
            sigma_2 <= delta_2 + sigma_2;
            dout    <= (sigma_2 >= BIAS);
        end
    end

    always_comb begin
        feedback = dout ? {2'b10, {(WIDTH){1'b0}}} : {2'b00, {(WIDTH){1'b0}}};
        delta_1  = {2'b00, din} - feedback;
        delta_2  = sigma_1 - feedback;
    end

endmodule
