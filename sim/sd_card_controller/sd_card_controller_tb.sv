`timescale 1ns / 1ps

module sd_card_controller_tb();

    // Sygnaly systemowe
    logic        clk;
    logic        rst;
    logic        rd_req;
    logic [31:0] rd_addr;
    logic        sd_ready;
    logic [7:0]  out_byte;
    logic        out_valid;
    
    // Sygnaly SPI
    logic        sd_cs;
    logic        sd_sck;
    logic        sd_mosi;
    logic        sd_miso;

    sd_card_controller dut (
        .clk(clk),
        .rst(rst),
        .rd_req(rd_req),
        .rd_addr(rd_addr),
        .sd_ready(sd_ready),
        .out_byte(out_byte),
        .out_valid(out_valid),
        .sd_cs(sd_cs),
        .sd_sck(sd_sck),
        .sd_mosi(sd_mosi),
        .sd_miso(sd_miso)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Zegar 100 MHz
    end

    
    // WIRTUALNA PAMIEC KARTY SD (Generowanie wzorca danych)
 
    logic [7:0] mock_ram [0:514]; // Token(1) + Dane(512) + CRC(2)
    
    initial begin
        mock_ram[0] = 8'hFE; // Data Token
        for (int i = 1; i <= 512; i++) mock_ram[i] = i[7:0]; // Wzorzec od 1 do 255 (przekreca sie)
        mock_ram[513] = 8'hBE; // Udawane CRC 1
        mock_ram[514] = 8'hEF; // Udawane CRC 2
    end


    logic [47:0] shift_in      = '0;
    logic [39:0] shift_out     = '1; 
    int          out_bits_left = 0;
    int          bit_cnt       = 0;
    int          acmd41_cnt    = 0;
    
    // Nowe zmienne dla obslugi bloku danych
    logic        sending_block    = 0;
    int          dummy_bits_wait  = 0;
    int          block_bytes_sent = 0;
    int          block_bits_sent  = 0;

    // A. Nasluch i dekodowanie
    initial begin
        forever begin
            @(posedge sd_sck);
            if (!sd_cs) begin
                shift_in = {shift_in[46:0], sd_mosi};
                bit_cnt++;
                
                if (bit_cnt == 48) begin
                    automatic logic [5:0] cmd_idx = shift_in[45:40];
                    
                    case (cmd_idx)
                        6'd0: begin
                            $display("[%0t] MOCK_SD: Odebrano CMD0. Zwracam 0x01", $time);
                            shift_out     = {8'h01, 32'hFFFFFFFF}; 
                            out_bits_left = 8;
                        end
                        6'd8: begin
                            $display("[%0t] MOCK_SD: Odebrano CMD8. Zwracam R7", $time);
                            shift_out     = {8'h01, 32'h000001AA}; 
                            out_bits_left = 40;
                        end
                        6'd55: begin
                            $display("[%0t] MOCK_SD: Odebrano CMD55. Zwracam 0x01", $time);
                            shift_out     = {8'h01, 32'hFFFFFFFF}; 
                            out_bits_left = 8;
                        end
                        6'd41: begin
                            if (acmd41_cnt == 0) begin
                                $display("[%0t] MOCK_SD: Odebrano ACMD41. Symuluje stan ZAJETA (0x01)", $time);
                                shift_out     = {8'h01, 32'hFFFFFFFF}; 
                                out_bits_left = 8;
                                acmd41_cnt++;
                            end else begin
                                $display("[%0t] MOCK_SD: Odebrano ACMD41. Symuluje stan GOTOWA (0x00)", $time);
                                shift_out     = {8'h00, 32'hFFFFFFFF}; 
                                out_bits_left = 8;
                            end
                        end
                        6'd17: begin
                            $display("[%0t] MOCK_SD: Odebrano CMD17. Przygotowuje blok 512 bajtow...", $time);
                            shift_out        = {8'h00, 32'hFFFFFFFF}; // R1 (Sukces)
                            out_bits_left    = 8;
                            sending_block    = 1;
                            dummy_bits_wait  = 16; // Czekamy 2 bajty (16 cykli zegara) przed wyrzuceniem Tokenu
                            block_bytes_sent = 0;
                            block_bits_sent  = 0;
                        end
                        default: begin
                            $display("[%0t] MOCK_SD: Nieznana komenda (idx: %d)!", $time, cmd_idx);
                            shift_out     = {8'hFF, 32'hFFFFFFFF};
                            out_bits_left = 8;
                        end
                    endcase
                end
            end
        end
    end

    // B. Wystawianie na MISO
    initial begin
        sd_miso = 1;
        forever begin
            @(negedge sd_sck or posedge sd_cs);
            if (sd_cs) begin
                sd_miso       = 1;
                bit_cnt       = 0;
                out_bits_left = 0;
                sending_block = 0;
            end else begin
                if (out_bits_left > 0) begin
                    // Wysylanie standardowych odpowiedzi (R1/R7)
                    sd_miso       = shift_out[39];
                    shift_out     = {shift_out[38:0], 1'b1};
                    out_bits_left--;
                end else if (sending_block) begin
                    // Wysylanie duzego bloku danych (Token + 512B + CRC)
                    if (dummy_bits_wait > 0) begin
                        sd_miso = 1; // Cisza przed tokenem
                        dummy_bits_wait--;
                    end else begin
                        sd_miso = mock_ram[block_bytes_sent][7 - block_bits_sent]; // MSB First
                        block_bits_sent++;
                        if (block_bits_sent == 8) begin
                            block_bits_sent = 0;
                            block_bytes_sent++;
                            if (block_bytes_sent == 515) begin
                                sending_block = 0; // Koniec calego bloku
                            end
                        end
                    end
                end else begin
                    sd_miso = 1;
                end
            end
        end
    end

    // GLOWNY PROCES TESTOWY I MONITOR DANYCH
  
    int bytes_received = 0;

    initial begin
        rst     = 1;
        rd_req  = 0;
        rd_addr = 0;
        #200 rst = 0;

        // ETAP 1: Oczekiwanie na inicjalizacje
        fork
            begin
                wait(sd_ready == 1'b1);
                $display("[%0t] SUKCES FSM: Karta zainicjalizowana. Przechodze do testu odczytu...", $time);
            end
            begin
                #15000000; 
                $error("[%0t] BLAD: Timeout inicjalizacji.", $time);
            end
        join_any
        disable fork;
        if (sd_ready !== 1'b1) $finish;

        #1000;

        // ETAP 2: Wyslanie rzadania odczytu sektora 100
        @(posedge clk);
        rd_addr = 32'd100;
        rd_req  = 1'b1;
        @(posedge clk);
        rd_req  = 1'b0;

        // ETAP 3: Nasluch i weryfikacja wyrzucanych danych
        fork
            begin
                while(bytes_received < 512) begin
                    @(posedge clk);
                    if (out_valid) begin
                        // Drukujemy tylko kilka pierwszych i ostatnich bajtow zeby nie zaspamowac konsoli
                        if (bytes_received < 3 || bytes_received > 509) begin
                             $display("[%0t] Otrzymano bajt [%0d]: %h", $time, bytes_received, out_byte);
                        end
                        if (bytes_received == 3) $display("    ... kolejne bajty ... ");
                        
                        bytes_received++;
                    end
                end
                
                // Po pobraniu 512 bajtow uklad musi pociagnac z karty jeszcze CRC i wrocic do IDLE
                wait(sd_ready == 1'b1);
                $display("[%0t] WERYFIKACJA OSTATECZNA SUKCES: Odczytano poprawnie 512 bajtow, uklad wrocil do IDLE.", $time);
            end
            begin
                // Przeznaczamy 2 milisekundy (czasu symulowanego) na test odczytu
                #30000000;
                $error("[%0t] BLAD: Timeout odczytu. Zlapano tylko %0d z 512 bajtow.", $time, bytes_received);
            end
        join_any
        disable fork;

        #5000;
        $display("[%0t] Symulacja logiki Issue #6 i #7 zakonczona.", $time);
        $finish;
    end

endmodule