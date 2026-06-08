`timescale 1ns / 1ps

module audio_fifo_tb();

    localparam DATA_WIDTH = 16;
    localparam ADDR_WIDTH = 3;  // Zmiana z 12 na 3 na potrzeby testu (Pojemnosc = 2^3 = 8)

    // Sygnaly
    logic                    clk;
    logic                    rst;
    logic                    wr_en;
    logic [DATA_WIDTH-1:0]   wr_data;
    logic                    rd_en;
    logic [DATA_WIDTH-1:0]   rd_data;
    logic                    empty;
    logic                    full;
    logic                    prog_empty;

    // Instancja testowanego bufora
    audio_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty),
        .full(full),
        .prog_empty(prog_empty)
    );

    // Zegar systemowy 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Scenariusz testowy
    initial begin
        // 0. Ustawienie stanu domyslnego
        rst     = 1;
        wr_en   = 0;
        wr_data = 0;
        rd_en   = 0;
        
        #25 rst = 0; // Puszczenie resetu gdzies w polowie cyklu
        @(posedge clk);
        #1;
        
        // TEST 1: Stan poczatkowy
 
        $display("[%0t] TEST 1: Stan poczatkowy...", $time);
        if (!empty) $error("BLAD: FIFO powinno byc puste po resecie.");
        if (!prog_empty) $error("BLAD: Flaga prog_empty powinna byc zapalona.");
        if (full) $error("BLAD: FIFO nie powinno byc pelne.");
        

        // TEST 2: Zapis do pelna (Burst Write)
        $display("[%0t] TEST 2: Ladowanie 8 elementow...", $time);
        for (int i = 0; i < 8; i++) begin
            wr_en = 1;
            wr_data = 16'hA000 + i; // Dane: A000, A001, A002...
            @(posedge clk);
            #1;
        end
        wr_en = 0;
        
        // Czekamy ulamkowa chwile, zeby flagi zaktualizowaly sie w modelu kombinacyjnym
        #1;
        if (!full) $error("BLAD: Oczekiwano flagi FULL.");
        if (empty) $error("BLAD: Flaga EMPTY nadal swieci.");
        

        // TEST 3: Zabezpieczenie przed przepelnieniem (Overflow)

        $display("[%0t] TEST 3: Wymuszanie przepelnienia (zapis 9 elementu)...", $time);
        wr_en = 1;
        wr_data = 16'hDEAD; // Tego nie powinno zapisac!
        @(posedge clk);
        #1;
        wr_en = 0;
        

        // TEST 4: Odczyt do pusta i weryfikacja danych

        $display("[%0t] TEST 4: Oproznianie bufora...", $time);
        for (int i = 0; i < 8; i++) begin
            rd_en = 1;
            @(posedge clk);
            #1; // Poczekaj na wyjscie z pamieci
            if (rd_data !== (16'hA000 + i)) 
                $error("BLAD ODCZYTU: Oczekiwano %h, otrzymano %h", (16'hA000 + i), rd_data);
        end
        rd_en = 0;
        
        #1;
        if (!empty) $error("BLAD: Oczekiwano flagi EMPTY po oproznieniu.");
        

        // TEST 5: Zabezpieczenie przed niedomiarem (Underflow)

        $display("[%0t] TEST 5: Wymuszanie odczytu z pustego bufora...", $time);
        rd_en = 1;
        @(posedge clk);
        #1;
        rd_en = 0;
        if (dut.rd_ptr !== 0) $error("BLAD: Wskaznik odczytu przesunal sie, mimo ze bufor byl pusty!");


        // TEST 6: Rownolegly odczyt i zapis (Zawijanie wskaznikow)

        $display("[%0t] TEST 6: Jednoczesny odczyt i zapis na przestrzeni 15 cykli...", $time);
        // Tworzymy lekki bufor (np. 3 elementy), zeby odczyt mial co robic
        wr_en = 1; wr_data = 16'hB001; @(posedge clk);
        wr_en = 1; wr_data = 16'hB002; @(posedge clk);
        wr_en = 1; wr_data = 16'hB003; @(posedge clk);
        
        // Teraz strzelamy na obu kanalach jednoczesnie (to wymusi przekrecenie wskaznikow w kółko)
        rd_en = 1;
        for (int i = 0; i < 15; i++) begin
            wr_data = 16'hC000 + i;
            @(posedge clk);
            #1;
        end
        
        wr_en = 0;
        rd_en = 0;
        
        #1;
        // Zapisalismy 3. Potem 15 dodalismy i 15 usunelismy jednoczesnie. Count powinien nadal wynosic 3.
        if (dut.count !== 3) 
            $error("BLAD: Konstrukcja count_nxt zawiodla. Oczekiwano 3, otrzymano %0d", dut.count);
        else 
            $display("[%0t] MATEMATYKA SUKCES: Licznik elementow utrzymal stan podczas symultanicznych transakcji.", $time);

        #100;
        $display("[%0t] Weryfikacja Audio FIFO zakonczona powodzeniem.", $time);
        $finish;
    end

endmodule