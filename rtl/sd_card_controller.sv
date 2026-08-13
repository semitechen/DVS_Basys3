`timescale 1ns / 1ps

module sd_card_controller (
    input  logic        clk,
    input  logic        rst,
    
    // Interfejs uzytkownika
    input  logic        rd_req,      
    input  logic [31:0] rd_addr,     
    output logic        sd_ready,    
    output logic [7:0]  out_byte,    
    output logic        out_valid,   
    
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

    // DEFINICJE KOMEND SD
    localparam [47:0] CMD0_RESET      = 48'h40_00_00_00_00_95; 
    localparam [47:0] CMD8_SEND_IF    = 48'h48_00_00_01_AA_87; 
    localparam [47:0] CMD55_APP_CMD   = 48'h77_00_00_00_00_01; 
    localparam [47:0] ACMD41_SD_SEND  = 48'h69_40_00_00_00_77; 

    typedef enum logic [3:0] {
        ST_POWER_ON,      
        ST_INIT_CMD0,     
        ST_INIT_CMD8,     
        ST_INIT_CMD55,    
        ST_INIT_ACMD41,   
        ST_INIT_DESELECT, 
        ST_IDLE,          
        ST_READ_CMD17,    
        ST_READ_WAIT_TOK, 
        ST_READ_DATA,     
        ST_READ_CRC       
    } state_t;

    state_t state, state_nxt;
    state_t next_init_state, next_init_state_nxt; 

    logic [3:0]  cmd_byte_idx, cmd_byte_idx_nxt; 
    logic [47:0] current_cmd, current_cmd_nxt;
    logic [7:0]  timeout_cnt, timeout_cnt_nxt;
    logic        sd_cs_reg, sd_cs_nxt;
    logic [9:0]  byte_cnt, byte_cnt_nxt;
    logic        sd_ready_reg, sd_ready_nxt;

    assign sd_cs    = sd_cs_reg;
    assign sd_ready = sd_ready_reg;

    always_comb begin
        state_nxt           = state;
        next_init_state_nxt = next_init_state;
        cmd_byte_idx_nxt    = cmd_byte_idx;
        current_cmd_nxt     = current_cmd;
        timeout_cnt_nxt     = timeout_cnt;
        sd_cs_nxt           = sd_cs_reg;
        sd_ready_nxt        = sd_ready_reg;
        byte_cnt_nxt        = byte_cnt;
        
        spi_start           = 1'b0;
        spi_data_in         = 8'hFF;
        spi_clk_div         = 16'd250; 
        out_valid           = 1'b0;
        out_byte            = 8'h00;

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
                        state_nxt = ST_INIT_CMD0;
                        timeout_cnt_nxt = '0;
                        cmd_byte_idx_nxt = '0;
                        current_cmd_nxt = CMD0_RESET; 
                    end
                end
            end

            ST_INIT_CMD0: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; 
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00}; 
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        
                        if (spi_data_out[7] == 1'b0) begin 
                            state_nxt = ST_INIT_DESELECT; 
                            next_init_state_nxt = ST_INIT_CMD8; 
                            cmd_byte_idx_nxt = '0;
                            timeout_cnt_nxt = '0;
                            sd_cs_nxt = 1'b1; 
                            current_cmd_nxt = CMD8_SEND_IF; 
                        end else begin
                            if (timeout_cnt < 8'd16) begin
                                timeout_cnt_nxt = timeout_cnt + 1;
                            end else begin
                                // Karta zignorowala komende - Agresywny reset cyklu
                                cmd_byte_idx_nxt = '0;
                                timeout_cnt_nxt = '0;
                                current_cmd_nxt = CMD0_RESET;
                                sd_cs_nxt = 1'b1; 
                            end
                        end
                    end
                end
            end
            
            ST_INIT_CMD8: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; 
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
                            timeout_cnt_nxt = '0;
                        end else begin
                            if (timeout_cnt < 8'd32) begin
                                timeout_cnt_nxt = timeout_cnt + 1;
                            end else begin
                                // Brak R7 / stara karta - pomijamy bledy i idziemy dalej
                                state_nxt = ST_INIT_DESELECT; 
                                next_init_state_nxt = ST_INIT_CMD55; 
                                cmd_byte_idx_nxt = '0;
                                timeout_cnt_nxt = '0;
                                sd_cs_nxt = 1'b1; 
                                current_cmd_nxt = CMD55_APP_CMD;
                            end
                        end
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                        
                        if (cmd_byte_idx == 10) begin
                            state_nxt = ST_INIT_DESELECT; 
                            next_init_state_nxt = ST_INIT_CMD55; 
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1; 
                            current_cmd_nxt = CMD55_APP_CMD; 
                        end
                    end
                end
            end
            
            ST_INIT_CMD55: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; 
                    if (cmd_byte_idx < 6) begin
                        spi_start = 1'b1;
                        spi_data_in = current_cmd[47-:8]; 
                        current_cmd_nxt = {current_cmd[39:0], 8'h00};
                        cmd_byte_idx_nxt = cmd_byte_idx + 1;
                    end else begin
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        
                        if (spi_data_out[7] == 1'b0) begin 
                            state_nxt = ST_INIT_DESELECT; 
                            next_init_state_nxt = ST_INIT_ACMD41; 
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1;
                            current_cmd_nxt = ACMD41_SD_SEND; 
                        end else begin
                            if (timeout_cnt < 8'd16) begin
                                timeout_cnt_nxt = timeout_cnt + 1;
                            end else begin
                                cmd_byte_idx_nxt = '0;
                                timeout_cnt_nxt = '0;
                                current_cmd_nxt = CMD55_APP_CMD;
                                sd_cs_nxt = 1'b1; 
                            end
                        end
                    end
                end
            end
            
            ST_INIT_ACMD41: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0; 
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
                                state_nxt = ST_IDLE; 
                            end else begin
                                state_nxt = ST_INIT_DESELECT; 
                                next_init_state_nxt = ST_INIT_CMD55; 
                                current_cmd_nxt = CMD55_APP_CMD; 
                            end
                            cmd_byte_idx_nxt = '0;
                            sd_cs_nxt = 1'b1;
                        end else begin
                             if (timeout_cnt < 8'd32) begin
                                timeout_cnt_nxt = timeout_cnt + 1;
                            end else begin
                                state_nxt = ST_INIT_DESELECT; 
                                next_init_state_nxt = ST_INIT_CMD55; 
                                current_cmd_nxt = CMD55_APP_CMD; 
                                cmd_byte_idx_nxt = '0;
                                sd_cs_nxt = 1'b1;
                            end
                        end
                    end
                end
            end

            ST_INIT_DESELECT: begin
                sd_cs_nxt = 1'b1; 
                if (spi_ready) begin
                    spi_start = 1'b1;
                    spi_data_in = 8'hFF; 
                    state_nxt = next_init_state; 
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
                    current_cmd_nxt = {8'h51, rd_addr, 8'hFF}; 
                    sd_cs_nxt = 1'b0; 
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
                        spi_start = 1'b1;
                        spi_data_in = 8'hFF;
                        state_nxt = ST_READ_WAIT_TOK;
                    end
                end
            end

            ST_READ_WAIT_TOK: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    if (spi_data_out == 8'hFE) begin
                        state_nxt = ST_READ_DATA;
                        byte_cnt_nxt = '0;
                    end
                    spi_start = 1'b1;
                    spi_data_in = 8'hFF;
                end
            end

            ST_READ_DATA: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    out_byte = spi_data_out;
                    out_valid = 1'b1; 
                    byte_cnt_nxt = byte_cnt + 1;
                    
                    if (byte_cnt == 511) begin
                        state_nxt = ST_READ_CRC;
                        byte_cnt_nxt = '0;
                    end
                    spi_start = 1'b1;
                    spi_data_in = 8'hFF;
                end
            end

            ST_READ_CRC: begin
                if (spi_ready) begin
                    sd_cs_nxt = 1'b0;
                    byte_cnt_nxt = byte_cnt + 1;
                    if (byte_cnt == 1) begin 
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
            state           <= ST_POWER_ON;
            next_init_state <= ST_POWER_ON;
            cmd_byte_idx    <= '0;
            current_cmd     <= '0;
            timeout_cnt     <= '0;
            sd_cs_reg       <= 1'b1;
            sd_ready_reg    <= 1'b0;
            byte_cnt        <= '0;
        end else begin
            state           <= state_nxt;
            next_init_state <= next_init_state_nxt;
            cmd_byte_idx    <= cmd_byte_idx_nxt;
            current_cmd     <= current_cmd_nxt;
            timeout_cnt     <= timeout_cnt_nxt;
            sd_cs_reg       <= sd_cs_nxt;
            sd_ready_reg    <= sd_ready_nxt;
            byte_cnt        <= byte_cnt_nxt;
        end
    end

endmodule