`timescale 1ns / 1ps

module dac_player #(
    parameter CLK_FREQ = 100_000_000,
    parameter SAMPLE_RATE = 44100
)(
    input  logic       clk,
    input  logic       rst,
    
    // Interfejs z Audio FIFO
    input  logic [7:0] fifo_rd_data,
    input  logic       fifo_empty,
    output logic       fifo_rd_en,
    
    // Interfejs fizyczny DAC
    output logic [7:0] dac
);

    localparam DIVIDER = CLK_FREQ / SAMPLE_RATE;
    localparam MAX_CNT = DIVIDER - 1;

    logic [15:0] tick_cnt;
    logic        tick;
    logic        rd_en_d1;

    // 1. Generator wolnego zegara (Tick)
    always_ff @(posedge clk) begin
        if (rst) begin
            tick_cnt <= '0;
            tick     <= 1'b0;
        end else begin
            if (tick_cnt == MAX_CNT[15:0]) begin
                tick_cnt <= '0;
                tick     <= 1'b1;
            end else begin
                tick_cnt <= tick_cnt + 1;
                tick     <= 1'b0;
            end
        end
    end

    // 2. Zadanie odczytu (tylko jesli w buforze sa dane)
    assign fifo_rd_en = tick && !fifo_empty;

    // 3. Pobranie danych i stabilizacja na wyjsciu
    // Pamięć BRAM zwraca dane jeden cykl po podniesieniu flagi rd_en.
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_en_d1 <= 1'b0;
            dac      <= 8'h00;
        end else begin
            rd_en_d1 <= fifo_rd_en;
            if (rd_en_d1) begin
                dac <= fifo_rd_data;
            end
        end
    end

endmodule