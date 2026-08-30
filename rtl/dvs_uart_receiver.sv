`timescale 1ns / 1ps

module dvs_uart_receiver (
    input  logic        clk,
    input  logic        rst,
    input  logic        rx_pin,
    
    // Zdekodowane sygnały dla silnika NCO
    output logic        ext_direction,
    output logic [15:0] ext_speed_factor
);

    logic       rx_done;
    logic [7:0] rx_data;

    // 1. Instancja warstwy fizycznej (nowy RX)
    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115_200)
    ) rx_unit (
        .clk(clk),
        .rst(rst),
        .rx_pin(rx_pin),
        .data_out(rx_data),
        .rx_done(rx_done)
    );

    // 2. Maszyna stanów dekodująca ramkę DVS
    typedef enum logic [1:0] {WAIT_SYNC, GET_DIR, GET_SPEED_H, GET_SPEED_L} state_t;
    state_t state, next_state;
    
    logic        dir_reg, next_dir;
    logic [15:0] speed_reg, next_speed;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= WAIT_SYNC;
            dir_reg <= 1'b1;          // Domyślnie FWD
            speed_reg <= 16'h1000;    // Domyślnie 1.0x (normalna prędkość)
        end else begin
            state <= next_state;
            dir_reg <= next_dir;
            speed_reg <= next_speed;
        end
    end

    always_comb begin
        next_state = state;
        next_dir = dir_reg;
        next_speed = speed_reg;

        if (rx_done) begin
            case (state)
                WAIT_SYNC: begin
                    if (rx_data == 8'hAA) begin
                        next_state = GET_DIR;
                    end
                end
                
                GET_DIR: begin
                    next_dir = rx_data[0];
                    next_state = GET_SPEED_H;
                end
                
                GET_SPEED_H: begin
                    next_speed[15:8] = rx_data;
                    next_state = GET_SPEED_L;
                end
                
                GET_SPEED_L: begin
                    next_speed[7:0] = rx_data;
                    next_state = WAIT_SYNC;
                end
            endcase
        end
    end

    assign ext_direction = dir_reg;
    assign ext_speed_factor = speed_reg;

endmodule