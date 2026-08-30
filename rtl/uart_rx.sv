`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  logic clk,
    input  logic rst,
    input  logic rx_pin,
    
    output logic [7:0] data_out,
    output logic       rx_done
);

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam HALF_PERIOD = BIT_PERIOD / 2;

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [31:0] clk_count;
    logic [2:0]  bit_index;
    logic [7:0]  data_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_reg  <= 0;
            data_out  <= 0;
            rx_done   <= 1'b0;
        end else begin
            // Impuls jednocyklowy (zerowany domyślnie)
            rx_done <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_pin == 1'b0) begin // Wykryto bit startu
                        state <= START;
                    end
                end

                START: begin
                    if (clk_count < HALF_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        // Weryfikacja na środku bitu (odrzucenie szumów)
                        if (rx_pin == 1'b0) begin
                            state <= DATA;
                        end else begin
                            state <= IDLE; 
                        end
                    end
                end

                DATA: begin
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        data_reg[bit_index] <= rx_pin; // Pobranie wartości na środku bitu

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= IDLE;
                        data_out <= data_reg;
                        rx_done  <= 1'b1; // Wystawienie flagi nowej paczki
                    end
                end
            endcase
        end
    end

endmodule