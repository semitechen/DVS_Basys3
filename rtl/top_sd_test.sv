`timescale 1ns / 1ps

module top_sd_test (
    input  logic        clk,      // 100 MHz
    input  logic        rst,      // Przycisk srodkowy (Reset)
    input  logic        btn_up,   // Przycisk gorny (Nastepny bajt)
    
    output logic [15:0] led,      // Diody LED
    
    // Piny do karty SD 
    output logic        sd_cs,
    output logic        sd_sck,
    output logic        sd_mosi,
    input  logic        sd_miso,
    
    // Wyjscie na DAC (na razie wisi w powietrzu, gotowe na przyszlosc)
    output logic [7:0]  dac
);

    // Sygnaly kontrolera SD
    logic        rd_req;
    logic [31:0] rd_addr;
    logic        sd_ready;
    logic [7:0]  out_byte;
    logic        out_valid;

    // 1. Instancja kontrolera SD
    sd_card_controller sd_ctrl_inst (
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

    // Adres testowy: poczatek karty (Sektor 0)
    assign rd_addr = 32'd0;

    // 2. Automatyczne wyzwolenie odczytu po udanej inicjalizacji
    logic prev_sd_ready = 0;
    always_ff @(posedge clk) begin
        if (rst) prev_sd_ready <= 0;
        else     prev_sd_ready <= sd_ready;
    end
    
    // Impuls rd_req pojawia sie dokladnie w momencie, gdy karta zglasza gotowosc
    assign rd_req = (sd_ready && !prev_sd_ready);


    // 3. Wewnetrzna pamiec na jeden sektor (512 bajtow)
    logic [7:0] sector_ram [0:511];
    logic [8:0] write_ptr = 0;

    always_ff @(posedge clk) begin
        if (rst || rd_req) begin
            write_ptr <= 0;
        end else if (out_valid) begin
            sector_ram[write_ptr] <= out_byte;
            write_ptr <= write_ptr + 1;
        end
    end


    // 4. czasowy debouncing przycisku (ok. 10 ms)
    logic [19:0] debounce_cnt = 0; // Licznik do 1 000 000
    logic        btn_state = 0;
    logic        prev_btn_state = 0;
    logic        step_req;

    always_ff @(posedge clk) begin
        if (rst) begin
            debounce_cnt   <= 0;
            btn_state      <= 0;
            prev_btn_state <= 0;
        end else begin
            // Zapamietanie poprzedniego stabilnego stanu
            prev_btn_state <= btn_state;
            
            // Jesli aktualny stan przycisku rozni sie od zapamietanego
            if (btn_up != btn_state) begin
                debounce_cnt <= debounce_cnt + 1;
                // Jesli stan utrzymuje sie przez 1 000 000 cykli (10 ms)
                if (debounce_cnt == 20'd1_000_000) begin
                    btn_state <= btn_up; // Zatwierdzamy nowy stan
                    debounce_cnt <= 0;
                end
            end else begin
                // Jesli blaszki drgaja i wracaja do starego stanu, resetujemy licznik
                debounce_cnt <= 0;
            end
        end
    end

    // Generowanie 1-taktowego impulsu TYLKO przy stabilnym wcisnieciu (zbocze narastajace)
    assign step_req = (btn_state == 1'b1) && (prev_btn_state == 1'b0);


    // 5. Wskaznik odczytu dla czlowieka
    logic [8:0] read_ptr = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            read_ptr <= 0;
        end else if (step_req) begin
            // Zabezpieczenie przed wyjsciem poza sektor
            if (read_ptr < 511) read_ptr <= read_ptr + 1;
        end
    end


    // 6. Przypisanie wyjsc
    // Diody LED[7:0] pokazuja wartosc aktualnego bajtu
    assign led[7:0] = sector_ram[read_ptr];
    
    // Diody LED[14:8] gasimy
    assign led[14:8] = 0;
    
    // Dioda LED[15] informuje, czy karta zostala poprawnie zainicjalizowana
    assign led[15] = sd_ready;
    
    // Testowe wystawienie wartosci na piny przyszlego DAC-a
    assign dac = sector_ram[read_ptr];

endmodule