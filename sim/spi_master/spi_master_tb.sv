`timescale 1ns / 1ps

module spi_master_tb();

    // Sygnaly testowe
    logic        clk;
    logic        rst;
    logic        start;
    logic [7:0]  data_in;
    logic [15:0] clk_div;
    logic [7:0]  data_out;
    logic        ready;
    logic        sck;
    logic        mosi;
    logic        miso;

    // Instancja testowanego modulu (DUT)
    spi_master dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .clk_div(clk_div),
        .data_out(data_out),
        .ready(ready),
        .sck(sck),
        .mosi(mosi),
        .miso(miso)
    );

    // 1. Generacja glownego zegara 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 2. Mock: udawana karta SD (Slave) w SPI Mode 0
    logic [7:0] mock_slave_data = 8'hA5; 
    int bit_idx = 7;
    
    initial begin
        miso = 1'b1; 
        forever begin
            @(negedge sck); 
            miso = mock_slave_data[bit_idx];
            
            if (bit_idx == 0) begin
                bit_idx = 7;
                mock_slave_data = ~mock_slave_data; 
            end else begin
                bit_idx--;
            end
        end
    end

    // 3. Glowny proces weryfikacyjny
    initial begin
        rst     = 1;
        start   = 0;
        data_in = 8'h00;
        clk_div = 16'd250; 
        
        #25;
        rst = 0;
        #20;

        // --- TEST 1: Powolna transmisja (Inicjalizacja) ---
        $display("[%0t] TEST 1: Wolny zegar (clk_div=250)", $time);
        data_in = 8'h55; 
        start   = 1;
        @(posedge clk);
        start   = 0;

        wait(ready == 1'b0); // CZEKAMY AZ UKLAD ZACZNIE PRACE
        wait(ready == 1'b1); // CZEKAMY AZ UKLAD SKONCZY PRACE
        
        if (data_out !== 8'hA5) $error("Błąd Testu 1: Odebrano %h zamiast A5", data_out);
        #1000;

        // --- TEST 2: Szybka transmisja z rekonfiguracja ---
        $display("[%0t] TEST 2: Szybki zegar (clk_div=2)", $time);
        clk_div = 16'd2; 
        data_in = 8'hFF; 
        start   = 1;
        @(posedge clk);
        start   = 0;

        wait(ready == 1'b0);
        wait(ready == 1'b1);
        
        if (data_out !== 8'h5A) $error("Błąd Testu 2: Odebrano %h zamiast 5A", data_out);
        #500;

        // --- TEST 3: Transmisja Back-to-Back ---
        $display("[%0t] TEST 3: Transmisja ciagla (Back-to-Back)", $time);
        data_in = 8'hC3;
        start   = 1;
        @(posedge clk);
        start   = 0;
        
        wait(ready == 1'b0);
        wait(ready == 1'b1);
        
        data_in = 8'h3C;
        start   = 1;
        @(posedge clk);
        start   = 0;

        wait(ready == 1'b0);
        wait(ready == 1'b1);
        
        if (data_out !== 8'h5A) $error("Błąd Testu 3: Zgubiona ramka w transmisji ciaglej %h", data_out);

        #500;
        $display("[%0t] Weryfikacja zakonczona.", $time);
        $finish;
        $finish;
    end

endmodule