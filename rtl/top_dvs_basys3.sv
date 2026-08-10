`timescale 1ns / 1ps

module top_dvs_basys3 (
    input  logic       clk,      // Zegar systemowy 100 MHz
    input  logic       rst,      // Przycisk srodkowy (Reset)

    input  logic       btn_up,   // Przycisk gorny (na przyszlosc)
    input  logic       btn_down, // Przycisk dolny

    // Interfejs SPI karty SD (Pmod JA - gorny rzad)
    output logic       sd_cs,
    output logic       sd_mosi,
    input  logic       sd_miso,
    output logic       sd_sck,

    // Wyjscie na 8-bitowa drabinke R-2R (Pmod JA dolny rzad + JXADC)
    output logic [7:0] dac
);


    // 1. SYGNALY WEWNETRZNE

    
    // SD Controller <-> BRAM Bridge
    logic        sd_rd_req;
    logic [31:0] sd_rd_addr;
    logic        sd_ready;
    logic [7:0]  sd_out_byte;
    logic        sd_out_valid;

    // BRAM Bridge <-> Audio FIFO
    logic        fifo_prog_empty;
    logic        fifo_wr_en;
    logic [7:0] fifo_wr_data; // UWAGA: Na ten moment masz to jako 16-bit!
    
    // Audio FIFO <-> DAC Player (Odtwarzacz - do napisania)
    logic        fifo_rd_en;
    logic [7:0] fifo_rd_data; 


    // 2. AUTOMATYCZNY START ODTWARZANIA
    
    logic prev_sd_ready = 0;
    logic auto_play_req;
    
    always_ff @(posedge clk) begin
        if (rst) prev_sd_ready <= 0;
        else     prev_sd_ready <= sd_ready;
    end
    
    // Generujemy 1-taktowy impuls play_req zaraz po zgloszeniu gotowosci karty
    assign auto_play_req = (sd_ready && !prev_sd_ready);

  
    // 3. INSTANCJE MODULOW


    // Poziom 1: Fizyczny odczyt z karty
    sd_card_controller sd_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .rd_req(sd_rd_req),
        .rd_addr(sd_rd_addr),
        .sd_ready(sd_ready),
        .out_byte(sd_out_byte),
        .out_valid(sd_out_valid),
        .sd_cs(sd_cs),
        .sd_sck(sd_sck),
        .sd_mosi(sd_mosi),
        .sd_miso(sd_miso)
    );

    // Poziom 2: Menadzer pamieci (Bridge)
    sd_bram_bridge bridge_inst (
        .clk(clk),
        .rst(rst),
        
        // Z warstwy wyzszej
        .play_req(auto_play_req),
        .start_addr(32'd0), 
        
        // Z kontrolera SD
        .sd_ready(sd_ready),
        .out_byte(sd_out_byte),
        .out_valid(sd_out_valid),
        .rd_req(sd_rd_req),
        .rd_addr(sd_rd_addr),
        
        // Z FIFO
        .prog_empty(fifo_prog_empty),
        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data)
    );

    // Poziom 3: Amortyzator pamieciowy (BRAM)
    audio_fifo fifo_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data),
        .rd_en(fifo_rd_en),
        .rd_data(fifo_rd_data),
        .prog_empty(fifo_prog_empty), 
        .empty(),
        .full()
    );


    // 4. TYMCZASOWE ZASLEPKI WYJSCIA
    
    
    assign dac = 8'h00;
    assign fifo_rd_en = 1'b0;

endmodule