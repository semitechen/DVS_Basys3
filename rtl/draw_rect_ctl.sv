module draw_rect_ctl (
    input  logic clk,
    input  logic rst_n,
    input  logic mouse_left,
    input  logic [11:0] mouse_xpos,
    input  logic [11:0] mouse_ypos,
    output logic [11:0] xpos,
    output logic [11:0] ypos
);

    // Grawitacja. Wartość 50 odpowiada ok. 0.2 piksela/klatkę^2
    localparam signed [19:0] GRAVITY = 20'd50; 
    

    localparam signed [19:0] FLOOR_Y = 20'd528 << 8; 

    logic [19:0] frame_counter;
    logic frame_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_counter <= '0;
            frame_tick <= 1'b0;
        end else begin
            // 40 000 000 Hz / 60 Hz = ~666666
            if (frame_counter >= 20'd666666) begin 
                frame_counter <= '0;
                frame_tick <= 1'b1; // Impuls trwający jeden takt zegara
            end else begin
                frame_counter <= frame_counter + 1;
                frame_tick <= 1'b0;
            end
        end
    end


    logic signed [19:0] y_pos_fp;
    logic signed [19:0] y_vel_fp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_pos_fp <= '0;
            y_vel_fp <= '0;
            xpos     <= '0;
            ypos     <= '0;
        end else begin
            if (!mouse_left) begin
                
                xpos <= mouse_xpos;
                ypos <= mouse_ypos;
                
               
                y_pos_fp <= {mouse_ypos, 8'd0}; 
                y_vel_fp <= '0;
            end else if (frame_tick) begin
                xpos <= mouse_xpos; 

                // Sprawdzanie kolizji z dnem
                if (y_pos_fp + y_vel_fp >= FLOOR_Y) begin
                    
                    y_pos_fp <= FLOOR_Y;
                    
                    y_vel_fp <= -((y_vel_fp * 8) / 10);
                end else begin
                    y_vel_fp <= y_vel_fp + GRAVITY;
                    y_pos_fp <= y_pos_fp + y_vel_fp;
                end
                
                ypos <= y_pos_fp[19:8];
            end
        end
    end

endmodule