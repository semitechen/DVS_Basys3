`timescale 1ns / 1ps

module spi_master (
    input  logic        clk,
    input  logic        rst,
    
  
    input  logic        start,
    input  logic [7:0]  data_in,
    input  logic [15:0] clk_div,
    output logic [7:0]  data_out,
    output logic        ready,
    
    // Interfejs SPI
    output logic        sck,
    output logic        mosi,
    input  logic        miso
);

    typedef enum logic [1:0] {
        IDLE = 2'd0,
        WORK = 2'd1,
        DONE = 2'd2
    } state_t;
    
    state_t state, state_nxt;

    logic [15:0] div_cnt;
    logic [2:0]  bit_cnt;
    logic [7:0]  tx_reg;
    logic [7:0]  rx_reg;
    logic        sck_reg;
    logic [7:0]  data_out_reg;

    logic [15:0] div_cnt_nxt;
    logic [2:0]  bit_cnt_nxt;
    logic [7:0]  tx_reg_nxt;
    logic [7:0]  rx_reg_nxt;
    logic        sck_reg_nxt;
    logic [7:0]  data_out_nxt;


    assign sck      = sck_reg;
    assign mosi     = tx_reg[7];
    assign ready    = (state == IDLE);
    assign data_out = data_out_reg;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            div_cnt      <= '0;
            bit_cnt      <= '0;
            tx_reg       <= '0;
            rx_reg       <= '0;
            sck_reg      <= 1'b0;
            data_out_reg <= '0;
        end else begin
            state        <= state_nxt;
            div_cnt      <= div_cnt_nxt;
            bit_cnt      <= bit_cnt_nxt;
            tx_reg       <= tx_reg_nxt;
            rx_reg       <= rx_reg_nxt;
            sck_reg      <= sck_reg_nxt;
            data_out_reg <= data_out_nxt;
        end
    end

    always_comb begin
        
        state_nxt    = state;
        div_cnt_nxt  = div_cnt;
        bit_cnt_nxt  = bit_cnt;
        tx_reg_nxt   = tx_reg;
        rx_reg_nxt   = rx_reg;
        sck_reg_nxt  = sck_reg;
        data_out_nxt = data_out_reg;

        case (state)
            IDLE: begin
                sck_reg_nxt = 1'b0;
                div_cnt_nxt = '0;
                bit_cnt_nxt = 3'd7;
                
                if (start) begin
                    tx_reg_nxt = data_in;
                    state_nxt  = WORK;
                end
            end
            
            WORK: begin
                if (div_cnt == clk_div) begin
                    div_cnt_nxt = '0;
                    sck_reg_nxt = ~sck_reg; 
                    
                    if (~sck_reg) begin
                        // Zegar z 0 na 1: Probkowanie wejscia
                        rx_reg_nxt = {rx_reg[6:0], miso};
                    end else begin
                        // Zegar z 1 na 0: Zmiana wystawianego bitu
                        tx_reg_nxt = {tx_reg[6:0], 1'b0};
                        
                        if (bit_cnt == 0) begin
                            state_nxt = DONE;
                        end else begin
                            bit_cnt_nxt = bit_cnt - 1;
                        end
                    end
                end else begin
                    div_cnt_nxt = div_cnt + 1;
                end
            end
            
            DONE: begin
                data_out_nxt = rx_reg;
                state_nxt    = IDLE;
            end
            
            default: begin
                state_nxt = IDLE;
            end
        endcase
    end

   

endmodule