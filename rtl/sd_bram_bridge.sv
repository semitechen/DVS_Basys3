`timescale 1ns / 1ps

/*
 * Author: Tomasz Jachymiak 
 */

module sd_bram_bridge (
    input  logic        clk,
    input  logic        rst,
    
    // Sygnały sterujące z selektora / UART
    input  logic        play_req,
    input  logic [31:0] start_addr,
    input  logic        direction,     // 1 = do przodu, 0 = do tyłu

    // Interfejs do kontrolera karty SD
    input  logic        sd_ready,
    input  logic [7:0]  out_byte,
    input  logic        out_valid,
    output logic        rd_req,
    output logic [31:0] rd_addr,

    // Interfejs do Audio FIFO
    input  logic        prog_full,      
    output logic        wr_en,
    output logic [7:0]  wr_data
);

    // Wewnętrzny bufor na jeden sektor (512 bajtów)
    logic [7:0] sector_buffer [0:511];
    logic [9:0] byte_cnt;

    typedef enum logic [2:0] {
        IDLE, WAIT_SD, READ_SECTOR, WAIT_FIFO, PUSH_FIFO, NEXT_SECTOR
    } state_t;
    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            rd_req   <= 0;
            wr_en    <= 0;
            rd_addr  <= 0;
            byte_cnt <= 0;
        end else begin
            rd_req <= 0; // Domyślnie brak żądania do karty SD
            wr_en  <= 0; // Domyślnie brak zapisu do FIFO
            
            case (state)
                IDLE: begin
                    if (play_req && sd_ready) begin
                        rd_addr <= start_addr;
                        state   <= WAIT_SD;
                    end
                end

                WAIT_SD: begin
                    if (!prog_full) begin // Czytaj tylko, jeśli FIFO ma miejsce
                        rd_req <= 1;
                        state  <= READ_SECTOR;
                        byte_cnt <= 0;
                    end
                end

                READ_SECTOR: begin
                    if (out_valid) begin
                        sector_buffer[byte_cnt] <= out_byte;
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == 511) begin
                            state <= WAIT_FIFO;
                            // Przygotowanie licznika do zrzutu (zależnie od kierunku)
                            byte_cnt <= direction ? 10'd0 : 10'd511; 
                        end
                    end
                end

                WAIT_FIFO: begin
                    // Czekamy jeden cykl na ustabilizowanie się pamięci RAM
                    state <= PUSH_FIFO;
                end

                PUSH_FIFO: begin
                    wr_en   <= 1;
                    wr_data <= sector_buffer[byte_cnt];
                    
                    if (direction == 1'b1) begin
                        // Do przodu
                        if (byte_cnt == 511) state <= NEXT_SECTOR;
                        else                 byte_cnt <= byte_cnt + 1;
                    end else begin
                        // Do tyłu
                        if (byte_cnt == 0) state <= NEXT_SECTOR;
                        else               byte_cnt <= byte_cnt - 1;
                    end
                end

                NEXT_SECTOR: begin
                    // Zmiana adresu z zachowaniem bezpiecznika (nie czytamy przed sektorem 0)
                    if (direction == 1'b1) begin
                        rd_addr <= rd_addr + 1;
                    end else begin
                        if (rd_addr > 0) rd_addr <= rd_addr - 1;
                    end
                    state <= WAIT_SD;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule