`timescale 1ns / 1ps

/*
Author: Tomasz Jachymiak
 */

module audio_fifo #(
    parameter DATA_WIDTH = 8, 
    parameter ADDR_WIDTH = 12  
)(
    input  logic clk,
    input  logic rst,
    
    input  logic wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    
    input  logic rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    
    output logic empty,
    output logic full,
    output logic  prog_empty 
);

    localparam FIFO_DEPTH = 2**ADDR_WIDTH;
    localparam PROG_EMPTY_THRESH = FIFO_DEPTH / 4; 

    // BRAM
    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    
    // Rejestry (stan obecny)
    logic [ADDR_WIDTH-1:0] wr_ptr, wr_ptr_nxt;
    logic [ADDR_WIDTH-1:0] rd_ptr, rd_ptr_nxt;
    logic [ADDR_WIDTH:0] count, count_nxt; 

    // Flagi (kombinacyjnie ze stanu obecnego)
    assign empty = (count == 0);
    assign full = (count == FIFO_DEPTH);
    assign prog_empty = (count <= PROG_EMPTY_THRESH);

    always_comb begin
        wr_ptr_nxt = wr_ptr;
        rd_ptr_nxt = rd_ptr;
        count_nxt  = count;

        if (wr_en && !full) begin
            wr_ptr_nxt = wr_ptr + 1;
            count_nxt  = count_nxt + 1;
        end

        if (rd_en && !empty) begin
            rd_ptr_nxt = rd_ptr + 1;
            count_nxt  = count_nxt - 1; // Uwaga: jesli w tym samym cyklu byl wr_en, to +1 i -1 sie znosza
        end
    end

    // Synchroniczny zapis do BRAM 
    // (BRAM musi byc sterowany sygnalem zegarowym, dlatego ma wlasny blok sekwencyjny)
    always_ff @(posedge clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
        end
    end

    // Synchroniczny odczyt z BRAM
    always_ff @(posedge clk) begin
        if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr];
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end else begin
            wr_ptr <= wr_ptr_nxt;
            rd_ptr <= rd_ptr_nxt;
            count  <= count_nxt;
        end
    end

endmodule