`timescale 1ns / 1ps

module xadc_interface (
    input  logic clk,
    input  logic rst,
    input  logic vauxp6,
    input  logic vauxn6,
    input  logic vauxp14,
    input  logic vauxn14,
    output logic [11:0] data_l,
    output logic [11:0] data_r,
    output logic        data_valid
);

    logic [6:0] daddr;
    logic       den;
    logic [15:0] do_out;
    logic       drdy;
    logic [4:0] channel_out;
    logic       eoc_out;

    typedef enum logic [1:0] {
        IDLE,
        READ_WAIT,
        CAPTURE
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            den <= 1'b0;
            daddr <= 7'h0;
            data_l <= 12'h0;
            data_r <= 12'h0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            case (state)
                IDLE: begin
                    if (eoc_out) begin
                        den <= 1'b1;
                        daddr <= {2'b00, channel_out};
                        state <= READ_WAIT;
                    end
                end
                READ_WAIT: begin
                    den <= 1'b0;
                    if (drdy) begin
                        if (channel_out == 5'h06) begin
                            data_l <= do_out[15:4];
                        end else if (channel_out == 5'h0E) begin
                            data_r <= do_out[15:4];
                            data_valid <= 1'b1;
                        end
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

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
