`timescale 1ns / 1ps

/*
 * Module: sd_bram_bridge
 * Author: Tomasz Jachymiak (Enhanced for Auto-Play & Robust Latching)
 * Description: Fetches 512-byte sectors from SD card and pushes to audio FIFO.
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
    output logic [7:0]  wr_data,

    // Diagnostyka
    output logic [2:0]  bridge_state,
    output logic        is_playing
);

    // Wewnętrzny bufor na jeden sektor (512 bajtów)
    logic [7:0] sector_buffer [0:511];
    logic [9:0] byte_cnt;

    typedef enum logic [2:0] {
        IDLE, WAIT_SD, READ_SECTOR, WAIT_FIFO, PUSH_FIFO, NEXT_SECTOR
    } state_t;
    state_t state;

    logic playing;
    logic pending_play_req;
    logic [31:0] pending_start_addr;

    assign bridge_state = state;
    assign is_playing   = playing;

    always_ff @(posedge clk) begin
        if (rst) begin
            state              <= IDLE;
            playing            <= 1'b0;
            pending_play_req   <= 1'b0;
            pending_start_addr <= 32'd0;
            rd_req             <= 0;
            wr_en              <= 0;
            rd_addr            <= 0;
            byte_cnt           <= 0;
        end else begin
            rd_req <= 0;
            wr_en  <= 0;

            // Zatrzask żądania odtworzenia
            if (play_req) begin
                pending_play_req   <= 1'b1;
                pending_start_addr <= start_addr;
            end
            
            case (state)
                IDLE: begin
                    // 1. Obsługa zatrzaśniętego żądania play_req
                    if (pending_play_req && sd_ready) begin
                        pending_play_req <= 1'b0;
                        playing          <= 1'b1;
                        rd_addr          <= pending_start_addr;
                        state            <= WAIT_SD;
                    end 
                    // 2. Automatyczny start odtwarzania pierwszego utworu po inicjalizacji karty SD
                    else if (!playing && sd_ready) begin
                        playing          <= 1'b1;
                        rd_addr          <= start_addr;
                        state            <= WAIT_SD;
                    end
                end

                WAIT_SD: begin
                    // Jeśli w trakcie odtwarzania przyszedł nowy play_req, zmień adres od razu
                    if (pending_play_req) begin
                        pending_play_req <= 1'b0;
                        rd_addr          <= pending_start_addr;
                    end

                    if (!prog_full && sd_ready) begin // Czytaj tylko, jeśli FIFO ma miejsce i SD gotowe
                        rd_req   <= 1;
                        state    <= READ_SECTOR;
                        byte_cnt <= 0;
                    end
                end

                READ_SECTOR: begin
                    if (out_valid) begin
                        sector_buffer[byte_cnt] <= out_byte;
                        byte_cnt <= byte_cnt + 10'd1;
                        if (byte_cnt == 10'd511) begin
                            state <= WAIT_FIFO;
                            // Przygotowanie licznika do zrzutu (zależnie od kierunku)
                            byte_cnt <= direction ? 10'd0 : 10'd511; 
                        end
                    end
                end

                WAIT_FIFO: begin
                    state <= PUSH_FIFO;
                end

                PUSH_FIFO: begin
                    wr_en   <= 1;
                    wr_data <= sector_buffer[byte_cnt];
                    
                    if (direction == 1'b1) begin
                        // Do przodu
                        if (byte_cnt == 10'd511) state <= NEXT_SECTOR;
                        else                     byte_cnt <= byte_cnt + 10'd1;
                    end else begin
                        // Do tyłu
                        if (byte_cnt == 10'd0) state <= NEXT_SECTOR;
                        else                   byte_cnt <= byte_cnt - 10'd1;
                    end
                end

                NEXT_SECTOR: begin
                    if (pending_play_req) begin
                        pending_play_req <= 1'b0;
                        rd_addr          <= pending_start_addr;
                    end else begin
                        if (direction == 1'b1) begin
                            rd_addr <= rd_addr + 32'd1;
                        end else begin
                            if (rd_addr > 0) rd_addr <= rd_addr - 32'd1;
                        end
                    end
                    state <= WAIT_SD;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule