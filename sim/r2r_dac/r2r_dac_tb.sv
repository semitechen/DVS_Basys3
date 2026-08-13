`timescale 1ns / 1ps

module r2r_dac_tb;

    localparam int INPUT_WIDTH = 16;
    localparam int DAC_WIDTH   = 8;

    logic                   clk;
    logic                   rst;
    logic [INPUT_WIDTH-1:0] din;
    logic [DAC_WIDTH-1:0]   dac_out;

    // Instantiate DUT
    r2r_dac #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .DAC_WIDTH(DAC_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .dac_out(dac_out)
    );

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        din = 16'sh0000;

        #20;
        rst = 0;

        // Test 1: Zero input (mid-scale DC offset bias -> should output 8'h80 = 128)
        din = 16'sh0000;
        #10;
        assert(dac_out == 8'h80) else $error("Test 1 Failed: Expected 8'h80, got %h", dac_out);

        // Test 2: Maximum positive input (+32767 -> should output 8'hFF = 255)
        din = 16'sh7FFF;
        #10;
        assert(dac_out == 8'hFF) else $error("Test 2 Failed: Expected 8'hFF, got %h", dac_out);

        // Test 3: Maximum negative input (-32768 -> should output 8'h00 = 0)
        din = 16'sh8000;
        #10;
        assert(dac_out == 8'h00) else $error("Test 3 Failed: Expected 8'h00, got %h", dac_out);

        // Test 4: Quarter positive scale (+16384 -> should output 8'hC0 = 192)
        din = 16'sh4000;
        #10;
        assert(dac_out == 8'hC0) else $error("Test 4 Failed: Expected 8'hC0, got %h", dac_out);

        // Test 5: Quarter negative scale (-16384 -> should output 8'h40 = 64)
        din = 16'shC000;
        #10;
        assert(dac_out == 8'h40) else $error("Test 5 Failed: Expected 8'h40, got %h", dac_out);

        $display("ALL R-2R DAC TESTS PASSED SUCCESSFULLY!");
        $finish;
    end

endmodule
