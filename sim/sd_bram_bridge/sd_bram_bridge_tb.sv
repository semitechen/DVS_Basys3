`timescale 1ns / 1ps

module sd_bram_bridge_tb();

    logic clk;
    logic rst;

    // Wejscia z systemu (zwykle podpiete przez przyciski / glowne FSM)
    logic  play_req;
    logic [31:0] start_addr;

    // Symulowany interfejs do karty SD 
    logic rd_req;
    logic [31:0] rd_addr;
    logic sd_ready;
    logic [7:0]  out_byte;
    logic out_valid;

    // Sprawdzamy interfejs do FIFO
    logic        prog_empty;
    logic        wr_en;
    logic [15:0] wr_data;

    // Instancja testowanego mostka
    sd_bram_bridge dut (
        .clk(clk),
        .rst(rst),
        .play_req(play_req),
        .start_addr(start_addr),
        .rd_req(rd_req),
        .rd_addr(rd_addr),
        .sd_ready(sd_ready),
        .out_byte(out_byte),
        .out_valid(out_valid),
        .prog_empty(prog_empty),
        .wr_en(wr_en),
        .wr_data(wr_data)
    );

    // Generator zegara systemowego 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Proces głowny weryfikacyjny
    initial begin
        
        rst  = 1;
        play_req = 0;
        start_addr = 0;
        sd_ready = 0;
        out_byte = 0;
        out_valid = 0;
        prog_empty = 0;
        
        #25 rst = 0;
        @(posedge clk); #1;
        
 
        // ETAP 1: Żądanie odtworzenia piosenki
   
        $display("[%0t] ETAP 1: Uruchamiam play_req na LBA 1024...", $time);
        start_addr = 32'd1024;
        play_req   = 1;
        @(posedge clk); #1;
        play_req   = 0;
        
        // Bufor rzekomo wysycha, a karta staje sie gotowa (warunek wyzwolenia rd_req)
        prog_empty = 1;
        sd_ready   = 1;
        
        @(posedge clk); #1;
        if (!rd_req) $error("BŁĄD: Mostek nie wystawił rd_req przy glodnym FIFO!");
        if (rd_addr !== 32'd1024) $error("BŁĄD: Mostek zaadresowal zly sektor!");
        $display("[%0t] SUKCES: Mostek zalazadal prawidlowego sektora.", $time);
        
        // Karta zaczyna szukac i po chwili odpowiada Tokenem
        sd_ready   = 0; // Karta "zajeta"
        #100;
        
     
        // ETAP 2: Wysylanie bajtów (Symulacja karty SD)
    
        $display("[%0t] ETAP 2: Karta wysyła pierwsze dwa bajty...", $time);
        
        // BAJT NR 0 (LSB pierwszego slowa np. 0xBB)
        out_byte  = 8'hBB;
        out_valid = 1;
        @(posedge clk); #1;
        out_valid = 0;
        
        if (wr_en) $error("BŁĄD: Mostek wystawil zapis do FIFO po jednym bajcie!");
        
        #50; // Karta przetwarza...
        
        // BAJT NR 1 (MSB pierwszego slowa np. 0xAA)
        out_byte  = 8'hAA;
        out_valid = 1;
        @(posedge clk); #1;
        out_valid = 0;
        
        // Sprawdzamy wyjscie do FIFO - spodziewamy sie zlozenia LSB + MSB => AABB
        if (!wr_en) $error("BŁĄD: Mostek nie odpalil zapisu do FIFO po drugim bajcie!");
        if (wr_data !== 16'hAABB) $error("BŁĄD ENDIANNESS: Oczekiwano AABB, otrzymano %h", wr_data);
        $display("[%0t] SUKCES: Mostek zlozyl 0xBB i 0xAA w slowo %h i wystawil wr_en.", $time, wr_data);
        
 
        // ETAP 3: Symulowanie kolejnego 16-bitowego pakietu 
 
        #50;
        $display("[%0t] ETAP 3: Karta wysyła bajt 2 i 3...", $time);
        
        // BAJT NR 2 (LSB drugiego slowa: 0x44)
        out_byte  = 8'h44;
        out_valid = 1;
        @(posedge clk); #1;
        out_valid = 0;
        
        #50;
        
        // BAJT NR 3 (MSB drugiego slowa: 0x33)
        out_byte  = 8'h33;
        out_valid = 1;
        @(posedge clk); #1;
        out_valid = 0;
        
        if (!wr_en) $error("BŁĄD: Mostek nie odpalil zapisu na bajcie nr 3!");
        if (wr_data !== 16'h3344) $error("BŁĄD ENDIANNESS: Oczekiwano 3344, otrzymano %h", wr_data);
        $display("[%0t] SUKCES: Mostek zlozyl 0x44 i 0x33 w slowo %h", $time, wr_data);

   
        // ETAP 4: Przeskok na nastepny sektor
  
        $display("[%0t] ETAP 4: Szybkie ukonczenie bloku 512B...", $time);
        for (int i = 4; i < 512; i++) begin
            out_byte  = i[7:0];
            out_valid = 1;
            @(posedge clk); #1;
            out_valid = 0;
            #10;
        end
        
        // Sprawdzenie powrotu do IDLE i wygenerowania drugiego rd_req na nastepny LBA
        prog_empty = 1;
        sd_ready   = 1;
        @(posedge clk); #1;
        
        if (!rd_req) $error("BŁĄD: FSM nie poprosil o nastepny sektor!");
        if (rd_addr !== 32'd1025) $error("BŁĄD: Zly adres drugiego sektora! Jest: %0d", rd_addr);
        $display("[%0t] SUKCES FSM: Adres pomyslnie inkrementowany (z 1024 na %0d).", $time, rd_addr);

        #100;
        $display("[%0t] Testy Issue #15 zakonczone.", $time);
        $finish;
    end

endmodule