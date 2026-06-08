`timescale 1ns / 1ps

module sd_bram_bridge (
    input  logic        clk,
    input  logic        rst,

    // Interfejs Sterowania (z warstwy wyzszej / przyciskow)
    input  logic        play_req,    // Impuls: zacznij odtwarzac nowy utwor
    input  logic [31:0] start_addr,  // Adres poczatkowy LBA z modulu track_lut

    // Interfejs z SD Card Controller
    output logic        rd_req,
    output logic [31:0] rd_addr,
    input  logic        sd_ready,
    input  logic [7:0]  out_byte,
    input  logic        out_valid,

    // Interfejs z Audio FIFO
    input  logic        prog_empty,
    output logic        wr_en,
    output logic [15:0] wr_data
);

    typedef enum logic {
        ST_IDLE,
        ST_FETCH_BLOCK
    } state_t;

    state_t state, state_nxt;

    // Rejestry wewnetrzne
    logic        playing, playing_nxt;
    logic [31:0] current_sector, current_sector_nxt;
    logic [8:0]  byte_cnt, byte_cnt_nxt;    // Liczy od 0 do 511
    logic [7:0]  temp_lsb, temp_lsb_nxt;    // Tymczasowa kieszen na pierwszy bajt

    // Rejestry wyjsciowe
    logic        rd_req_reg, rd_req_nxt;
    logic [31:0] rd_addr_reg, rd_addr_nxt;
    logic        wr_en_reg, wr_en_nxt;
    logic [15:0] wr_data_reg, wr_data_nxt;

    // Bezposrednie przypisanie wyjsc do przerzutnikow
    assign rd_req  = rd_req_reg;
    assign rd_addr = rd_addr_reg;
    assign wr_en   = wr_en_reg;
    assign wr_data = wr_data_reg;


    always_comb begin
      
        state_nxt          = state;
        playing_nxt        = playing;
        current_sector_nxt = current_sector;
        byte_cnt_nxt       = byte_cnt;
        temp_lsb_nxt       = temp_lsb;
        
        rd_addr_nxt        = rd_addr_reg;
        wr_data_nxt        = wr_data_reg;
        
        // Sgnaly impulsowe zawsze wracaja do zera!
        rd_req_nxt         = 1'b0; 
        wr_en_nxt          = 1'b0;

        // Nadrzedne polecenie odtworzenia utworu
        if (play_req) begin
            playing_nxt        = 1'b1;
            current_sector_nxt = start_addr;
            // Jesli przyszlo zadanie nowej piosenki, resetujemy FSM
            state_nxt          = ST_IDLE; 
        end

        //Maszyna Stanów
        case (state)
            ST_IDLE: begin
                // Czekamy na sygnal z FIFO i gotowosc karty SD
                if (playing && prog_empty && sd_ready) begin
                    rd_req_nxt  = 1'b1;
                    rd_addr_nxt = current_sector;
                    
                    current_sector_nxt = current_sector + 1; // Przygotowanie adresu na nastepny blok
                    byte_cnt_nxt       = '0;
                    state_nxt          = ST_FETCH_BLOCK;
                end
            end

            ST_FETCH_BLOCK: begin
                if (out_valid) begin
                    byte_cnt_nxt = byte_cnt + 1;

                    // Bit [0] licznika informuje nas, czy to bajt parzysty czy nieparzysty
                    if (byte_cnt[0] == 1'b0) begin
                        // Bajt 0, 2, 4... (Little Endian: LSB)
                        temp_lsb_nxt = out_byte;
                    end else begin
                        // Bajt 1, 3, 5... (Little Endian: MSB)
                        wr_data_nxt = {out_byte, temp_lsb}; // {MSB, LSB}
                        wr_en_nxt   = 1'b1; // Impuls zapisu do FIFO na 1 cykl zegara!
                    end

                    if (byte_cnt == 511) begin
                        state_nxt = ST_IDLE; // Zebrano caly blok 512 bajtow (256 slow)
                    end
                end
            end
        endcase
    end


    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            playing <= 1'b0;
            current_sector <= '0;
            byte_cnt <= '0;
            temp_lsb <= '0;
            
            rd_req_reg <= 1'b0;
            rd_addr_reg <= '0;
            wr_en_reg <= 1'b0;
            wr_data_reg <= '0;
        end else begin
            state <= state_nxt;
            playing <= playing_nxt;
            current_sector <= current_sector_nxt;
            byte_cnt <= byte_cnt_nxt;
            temp_lsb <= temp_lsb_nxt;
            
            rd_req_reg <= rd_req_nxt;
            rd_addr_reg <= rd_addr_nxt;
            wr_en_reg <= wr_en_nxt;
            wr_data_reg <= wr_data_nxt;
        end
    end

endmodule