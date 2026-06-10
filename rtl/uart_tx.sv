`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  logic clk,
    input  logic rst,
    input  logic [7:0] data_in,
    input  logic tx_start,
    output logic tx_pin,
    output logic tx_busy
);

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [31:0] clk_count;
    logic [2:0]  bit_index;
    logic [7:0]  data_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_pin <= 1'b1;
            tx_busy <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_pin <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        data_reg <= data_in;
                        tx_busy <= 1'b1;
                        state <= START;
                        clk_count <= 0;
                    end
                end

                START: begin
                    tx_pin <= 1'b0;
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                        bit_index <= 0;
                    end
                end

                DATA: begin
                    tx_pin <= data_reg[bit_index];
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_pin <= 1'b1;
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
