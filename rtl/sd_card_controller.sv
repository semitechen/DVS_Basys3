`timescale 1ns / 1ps

module sd_card_controller (
    input  logic        clk,
    input  logic        rst,
    
    // Interfejs uzytkownika (Audio Player / FSM Nadrzedna)
    input  logic        rd_req,      // Zadanie odczytu bloku 512 bajtow
    input  logic [31:0] rd_addr,     // Adres sektora (LBA) z LUT
    output logic        sd_ready,    // 1 = Karta zainicjalizowana
    output logic [7:0]  out_byte,    // Pojedynczy bajt odczytany z karty
    output logic        out_valid,   // Impuls 1-taktowy: out_byte jest wazny
    
    output logic        sd_cs,
    output logic        sd_sck,
    output logic        sd_mosi,
    input  logic        sd_miso
);

    logic        spi_start;
    logic [7:0]  spi_data_in;
    logic [15:0] spi_clk_div;
    logic [7:0]  spi_data_out;
    logic        spi_ready;

    spi_master spi_inst (
        .clk(clk),
        .rst(rst),
        .start(spi_start),
        .data_in(spi_data_in),
        .clk_div(spi_clk_div),
        .data_out(spi_data_out),
        .ready(spi_ready),
        .sck(sd_sck),
        .mosi(sd_mosi),
        .miso(sd_miso)
    );

    // DEFINICJE KOMEND SD (Format: {Rozkaz, Argument[31:0], CRC})
    localparam [47:0] CMD0_RESET      = 48'h40_00_00_00_00_95; // GO_IDLE_STATE
    localparam [47:0] CMD8_SEND_IF    = 48'h48_00_00_01_AA_87; // SEND_IF_COND
    localparam [47:0] CMD55_APP_CMD   = 48'h77_00_00_00_00_01; // APP_CMD (Zawsze przed ACMD)
    localparam [47:0] ACMD41_SD_SEND  = 48'h69_40_00_00_00_77; // SD_SEND_OP_COND (HCS=1)

    typedef enum logic [3:0] {
        ST_POWER_ON,      // Generowanie min. 74 impulsow zegara przy CS=1
        ST_INIT_CMD0,     // Wysylanie CMD0 (Reset)
        ST_INIT_CMD8,     // Wysylanie CMD8 (Check Voltage)
        ST_INIT_CMD55,    // Wysylanie CMD55
        ST_INIT_ACMD41,   // Wysylanie ACMD41
        ST_IDLE,          // Karta gotowa (sd_ready = 1). Czeka na rd_req
        ST_READ_CMD17,    // Wyslanie CMD17 (Read Single Block)
        ST_READ_WAIT_TOK, // Czekanie na Data Token (0xFE)
        ST_READ_DATA,     // Odbior 512 bajtow
        ST_READ_CRC       // Odbior 2 bajtow CRC i powrot do ST_IDLE
    } state_t;

    state_t state, state_nxt;

    // Sub-stany dla wysylania 6-bajtowej komendy
    logic [3:0]  cmd_byte_idx, cmd_byte_idx_nxt; 
    logic [47:0] current_cmd, current_cmd_nxt;
    logic [7:0]  timeout_cnt, timeout_cnt_nxt;
    logic        sd_cs_reg, sd_cs_nxt;

    logic [9:0] byte_cnt, byte_cnt_nxt;
    // Rejestry wyjsciowe
    logic sd_ready_reg, sd_ready_nxt;

    assign sd_cs    = sd_cs_reg;
    assign sd_ready = sd_ready_reg;

    always_comb begin
        state_nxt        = state;
        cmd_byte_idx_nxt = cmd_byte_idx;
        current_cmd_nxt  = current_cmd;
        timeout_cnt_nxt  = timeout_cnt;
        sd_cs_nxt        = sd_cs_reg;
        sd_ready_nxt     = sd_ready_reg;
        
        spi_start        = 1'b0;
        spi_data_in      = 8'hFF;
        spi_clk_div      = 16'd250; // Domyslnie wolny zegar (400 kHz)
        out_valid        = 1'b0;
        out_byte         = 8'h00;

        case (state)
            ST_POWER_ON: begin
                sd_cs_nxt = 1'b1;
                sd_ready_nxt = 1'b0;
                
                if (spi_ready) begin
                    if (timeout_cnt < 10) begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        timeout_cnt_nxt = timeout_cnt + 1;
                    end else begin
                        // SUKCES: 10 bajtow wyslane i SPI zglosilo gotowosc.
                        state_nxt = ST_INIT_CMD0;
                        timeout_cnt_nxt = '0;
                        cmd_byte_idx_nxt = '0;
                        current_cmd_nxt = CMD0_RESET; // PRELOAD: ladujemy CMD0 z wyprzedzeniem
                    end
                end
            end

            ST_INIT_CMD0: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; // POPRAWIONE: CS opada tylko, gdy SPI jest gotowe
                    
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00}; 
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        
                        if (spi_data_out[7] == 1'b0) begin 
                            state_nxt = ST_INIT_CMD8;
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1; 
                            current_cmd_nxt = CMD8_SEND_IF; // PRELOAD: ladujemy CMD8
                        end
                    end
                end
            end
            
            ST_INIT_CMD8: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; // POPRAWIONE
                    
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00};
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else if (cmd_byte_idx == 6) begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        
                        if (spi_data_out[7] == 1'b0) begin 
                            cmd_byte_idx_nxt = 7;
                        end
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                        
                        if (cmd_byte_idx == 10) begin
                            state_nxt = ST_INIT_CMD55;
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1; 
                            current_cmd_nxt = CMD55_APP_CMD; // PRELOAD: ladujemy CMD55
                        end
                    end
                end
            end
            
            ST_INIT_CMD55: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; // POPRAWIONE
                    
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00};
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        
                        if (spi_data_out[7] == 1'b0) begin 
                            state_nxt = ST_INIT_ACMD41;
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1;
                            current_cmd_nxt = ACMD41_SD_SEND; // PRELOAD: ladujemy ACMD41
                        end
                    end
                end
            end
            
            ST_INIT_ACMD41: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; // POPRAWIONE
                    
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00};
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        
                        if (spi_data_out[7] == 1'b0) begin 
                            if (spi_data_out == 8'h00) begin
                                state_nxt = ST_IDLE; // GOTOWE
                            end else begin
                                state_nxt = ST_INIT_CMD55; // Pętla: powrot do CMD55
                                current_cmd_nxt = CMD55_APP_CMD; // PRELOAD na powrót
                            end
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1;
                        end
                    end
                end
            end

            ST_IDLE: begin
                sd_cs_nxt = 1'b1;
                sd_ready_nxt = 1'b1; 
                spi_clk_div = 16'd2; 
                
                if (rd_req) begin
                    sd_ready_nxt = 1'b0;
                    state_nxt = ST_READ_CMD17;
                    cmd_byte_idx_nxt = '0;
                    // CMD17 to rozkaz 0x51. Po nim lecą 4 bajty adresu i puste CRC 0xFF
                    current_cmd_nxt = {8'h51, rd_addr, 8'hFF}; 
                    sd_cs_nxt = 1'b0; // Opuszczamy CS dla nowej transakcji
                end
            end

            ST_READ_CMD17: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00};
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else begin
                        // Komenda poszla. Uruchamiamy zegar w ciemno i czekamy na token
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        state_nxt = ST_READ_WAIT_TOK;
                    end
                end
            end

            ST_READ_WAIT_TOK: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    
                    // Jeżeli doczekaliśmy się bajtu 0xFE, karta zaczyna słać dane
                    if (spi_data_out == 8'hFE) begin
                        state_nxt = ST_READ_DATA;
                        byte_cnt_nxt = '0;
                    end
                    
                    // Zmuszamy Mastera do kolejnego cyklu czytania
                    spi_start = 1'b1;
                    spi_data_in = 8'hFF;
                end
            end

            ST_READ_DATA: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    
                    // 1. Wystawiamy odczytany bajt z poprzedniego cyklu na zewnatrz
                    out_byte = spi_data_out;
                    out_valid = 1'b1; 
                    
                    // 2. Kontrolujemy licznik odebranych bajtow
                    byte_cnt_nxt = byte_cnt + 1;
                    
                    if (byte_cnt == 511) begin
                        // To był ostatni bajt. Przechodzimy do czytania CRC
                        state_nxt = ST_READ_CRC;
                        byte_cnt_nxt = '0;
                    end
                    
                    // 3. Pompujemy zegar dla pobrania następnego bajtu
                    spi_start = 1'b1;
                    spi_data_in = 8'hFF;
                end
            end

            ST_READ_CRC: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    
                    byte_cnt_nxt = byte_cnt + 1;
                    if (byte_cnt == 1) begin 
                        // Po zignorowaniu 2 bajtów CRC podnosimy CS i wracamy do IDLE
                        state_nxt = ST_IDLE;
                        sd_cs_nxt = 1'b1; 
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                    end
                end
            end

            default: state_nxt = ST_POWER_ON;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state        <= ST_POWER_ON;
            cmd_byte_idx <= '0;
            current_cmd  <= '0;
            timeout_cnt  <= '0;
            sd_cs_reg    <= 1'b1;
            sd_ready_reg <= 1'b0;
            byte_cnt <= '0;
        end else begin
            state        <= state_nxt;
            cmd_byte_idx <= cmd_byte_idx_nxt;
            current_cmd  <= current_cmd_nxt;
            timeout_cnt  <= timeout_cnt_nxt;
            sd_cs_reg    <= sd_cs_nxt;
            sd_ready_reg <= sd_ready_nxt;
            byte_cnt <= byte_cnt_nxt;
        end
    end

endmodule