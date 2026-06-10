`timescale 1ns / 1ps

module char_rom #(
    parameter TEXT = {
        "                                ",
        "                                ",
        "                                ",
        "   testing drawing characters   ",
        "    32 x 8 characters rect      ",
        "                                ",
        "                                ",
        "                                "
    }
)(
    input  logic clk,
    input  logic [7:0] char_xy,
    output logic [6:0] char_code
);

    always_ff @(posedge clk) begin
        char_code <= TEXT[(255 - char_xy) * 8 +: 7];
    end

endmodule
