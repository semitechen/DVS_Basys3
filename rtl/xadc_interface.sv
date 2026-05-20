`timescale 1ns / 1ps

module xadc_interface (
    input  logic clk,
    input  logic rst,
    input  logic vauxp6,
    input  logic vauxn6,
    input  logic vauxp14,
    input  logic vauxn14,
    input  logic [6:0] daddr,
    input  logic den,
    output logic [15:0] do_out,
    output logic drdy,
    output logic [4:0] channel_out,
    output logic eoc_out
);

    XADC #(
        .INIT_40(16'h1000),
        .INIT_41(16'h2000),
        .INIT_42(16'h0400),
        .INIT_48(16'h0000),
        .INIT_49(16'h4040),
        .INIT_4A(16'h0000),
        .INIT_4B(16'h4040),
        .SIM_DEVICE("7SERIES")
    ) xadc_inst (
        .DCLK(clk),
        .RESET(rst),
        .DADDR(daddr),
        .DEN(den),
        .DWE(1'b0),
        .DI(16'h0),
        .DO(do_out),
        .DRDY(drdy),
        .VP(1'b0),
        .VN(1'b0),
        .VAUXP({1'b0, vauxp14, 7'b0, vauxp6, 6'b0}),
        .VAUXN({1'b0, vauxn14, 7'b0, vauxn6, 6'b0}),
        .CHANNEL(channel_out),
        .EOC(eoc_out),
        .EOS(),
        .BUSY(),
        .ALM(),
        .MUXADDR()
    );

endmodule
