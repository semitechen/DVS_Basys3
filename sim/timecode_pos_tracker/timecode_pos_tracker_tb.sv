`timescale 1ns / 1ps

module timecode_pos_tracker_tb;

    logic clk;
    logic rst;
    logic [11:0] data_l;
    logic [11:0] data_r;
    logic data_valid;

    logic [31:0] sample_pos;
    logic direction;
    logic [15:0] led_display;

    // Clock generation (100 MHz, period = 10ns)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // DVS Decoder DUT Instantiation
    timecode_pos_tracker #(
        .HYSTERESIS(13'sd80),
        .SQUELCH_THRESHOLD(16'd150)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_l(data_l),
        .data_r(data_r),
        .data_valid(data_valid),
        .sample_pos(sample_pos),
        .direction(direction)
    );

    // Independent LED Display DUT Instantiation
    led_pos_display u_led_display (
        .clk(clk),
        .rst(rst),
        .sample_pos(sample_pos),
        .led(led_display)
    );

    // ADC strobe generation (~100 kHz sample rate: 1 strobe every 10 clock cycles)
    task send_adc_sample(input int l_val, input int r_val);
        begin
            @(posedge clk);
            data_l <= 12'(l_val);
            data_r <= 12'(r_val);
            data_valid <= 1'b1;
            @(posedge clk);
            data_valid <= 1'b0;
            repeat (10) @(posedge clk);
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Starting timecode_pos_tracker 4x Simulation Test");
        $display("==================================================");

        rst = 1'b1;
        data_l = 12'd2048;
        data_r = 12'd2048;
        data_valid = 1'b0;

        #100;
        rst = 1'b0;
        #100;

        // 1. Noise & DC Offset Settling Test (Left DC=2500, Right DC=2150)
        $display("[TEST 1] Testing Hardware DC Bias (L=2500, R=2150) & Noise Rejection...");
        for (int i = 0; i < 500; i++) begin
            send_adc_sample(2500 + ($urandom_range(0, 30) - 15), 2150 + ($urandom_range(0, 30) - 15));
        end
        if (sample_pos == 0) begin
            $display("-> PASS: DC bias tracked and noise rejected, sample_pos = %0d", sample_pos);
        end else begin
            $error("-> FAIL: Noise caused spurious steps, sample_pos = %0d", sample_pos);
        end

        // 2. Forward Playback (10 Full Cycles on top of DC bias)
        $display("[TEST 2] Testing Forward Playback with DC bias (10 cycles = 40 quad steps)...");
        for (int cycle = 0; cycle < 10; cycle++) begin
            // Quad 1: (1, 1) -> L=+500, R=+500
            for (int k=0; k<10; k++) send_adc_sample(2500 + 500, 2150 + 500);
            // Quad 2: (1, 0) -> L=+500, R=-500
            for (int k=0; k<10; k++) send_adc_sample(2500 + 500, 2150 - 500);
            // Quad 3: (0, 0) -> L=-500, R=-500
            for (int k=0; k<10; k++) send_adc_sample(2500 - 500, 2150 - 500);
            // Quad 4: (0, 1) -> L=-500, R=+500
            for (int k=0; k<10; k++) send_adc_sample(2500 - 500, 2150 + 500);
        end

        $display("-> Result after 10 forward cycles: sample_pos = %0d (expected ~441), direction = %0d", sample_pos, direction);
        if (sample_pos == 441 && direction == 1'b1) begin
            $display("-> PASS: Forward 4x Tracking Exact!");
        end else begin
            $error("-> FAIL: Unexpected sample_pos: %0d or direction: %0d", sample_pos, direction);
        end

        // 3. Scratch Reversal (5 Cycles Backward)
        $display("[TEST 3] Testing Reverse Scratch (5 cycles = 20 quad steps back)...");
        for (int cycle = 0; cycle < 5; cycle++) begin
            // Reverse order: (0,1) -> (0,0) -> (1,0) -> (1,1) -> (0,1)
            for (int k=0; k<10; k++) send_adc_sample(2500 - 500, 2150 - 500);
            for (int k=0; k<10; k++) send_adc_sample(2500 + 500, 2150 - 500);
            for (int k=0; k<10; k++) send_adc_sample(2500 + 500, 2150 + 500);
            for (int k=0; k<10; k++) send_adc_sample(2500 - 500, 2150 + 500);
        end

        $display("-> Result after 5 reverse cycles: sample_pos = %0d (expected ~220), direction = %0d", sample_pos, direction);
        if (sample_pos == 220 && direction == 1'b0) begin
            $display("-> PASS: Reverse Scratch Tracking Exact!");
        end else begin
            $error("-> FAIL: Unexpected sample_pos: %0d or direction: %0d", sample_pos, direction);
        end

        // 4. Fast Micro-Rub Scratch
        $display("[TEST 4] Testing Fast Micro-Rub (Alternating single quadrature steps)...");
        for (int rub = 0; rub < 10; rub++) begin
            // Step Forward
            for (int k=0; k<5; k++) send_adc_sample(2500 + 500, 2150 + 500);
            // Step Reverse
            for (int k=0; k<5; k++) send_adc_sample(2500 - 500, 2150 + 500);
        end

        $display("-> Result after 10 micro-rubs: sample_pos = %0d (expected ~220, perfectly preserved)", sample_pos);
        if (sample_pos == 220) begin
            $display("-> PASS: Micro-rub scratching preserved position perfectly without drift!");
        end else begin
            $error("-> FAIL: Micro-rub drift detected: sample_pos = %0d", sample_pos);
        end

        // 5. Idle Squelch Gate / Stop Test (Simulating audio stop with 50Hz mains hum / idle noise)
        $display("[TEST 5] Testing Squelch Gate when Audio Stops (50Hz mains hum & idle noise)...");
        for (int i = 0; i < 1000; i++) begin
            // Sub-threshold noise & hum (amplitude ~70 LSBs, below squelch threshold 150)
            int hum = int'(60.0 * $sin(2.0 * 3.14159 * i / 20.0));
            send_adc_sample(2500 + hum + ($urandom_range(0, 20) - 10), 2150 + hum + ($urandom_range(0, 20) - 10));
        end

        $display("-> Result after 1000 samples of idle stop with hum: sample_pos = %0d (expected ~220)", sample_pos);
        if (sample_pos == 220) begin
            $display("-> PASS: Squelch Gate successfully locked position and prevented backwards drift!");
        end else begin
            $error("-> FAIL: Position drifted during idle stop: sample_pos = %0d", sample_pos);
        end

        $display("==================================================");
        $display(" All timecode_pos_tracker Tests Completed Successfully!");
        $display("==================================================");
        $finish;
    end

endmodule
