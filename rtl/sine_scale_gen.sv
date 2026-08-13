`timescale 1ns / 1ps
/**
 * Module: sine_scale_gen
 * Project: DVS_Basys3
 * Description: Synthesizes the C Major Scale (C3 to C4) using DDS.
 *              Plays each note for 250 ms continuously in a loop.
 *
 * Notes & Frequencies (A4 = 440Hz):
 * 0: C3 = 130.81 Hz
 * 1: D3 = 146.83 Hz
 * 2: E3 = 164.81 Hz
 * 3: F3 = 174.61 Hz
 * 4: G3 = 196.00 Hz
 * 5: A3 = 220.00 Hz
 * 6: B3 = 246.94 Hz
 * 7: C4 = 261.63 Hz
 */

module sine_scale_gen (
    input  logic        clk,        // 100 MHz System Clock
    input  logic        rst,
    output logic [15:0] sine_out,   // 16-bit signed PCM audio sample
    output logic [2:0]  note_idx_out // Current note index (0..7) for visual diagnostics
);

    // 256-sample 16-bit Signed Sine Wave Look-Up Table
    logic [15:0] sine_lut [0:255];
    initial begin
        sine_lut[0] = 16'h0000; sine_lut[1] = 16'h0324; sine_lut[2] = 16'h0647; sine_lut[3] = 16'h096a;
        sine_lut[4] = 16'h0c8b; sine_lut[5] = 16'h0fab; sine_lut[6] = 16'h12c8; sine_lut[7] = 16'h15e3;
        sine_lut[8] = 16'h18f8; sine_lut[9] = 16'h1c0b; sine_lut[10] = 16'h1f1a; sine_lut[11] = 16'h2223;
        sine_lut[12] = 16'h2528; sine_lut[13] = 16'h2827; sine_lut[14] = 16'h2b1f; sine_lut[15] = 16'h2e11;
        sine_lut[16] = 16'h30fb; sine_lut[17] = 16'h33de; sine_lut[18] = 16'h36ba; sine_lut[19] = 16'h398c;
        sine_lut[20] = 16'h3c54; sine_lut[21] = 16'h3f11; sine_lut[22] = 16'h41c2; sine_lut[23] = 16'h446a;
        sine_lut[24] = 16'h4705; sine_lut[25] = 16'h4993; sine_lut[26] = 16'h4c14; sine_lut[27] = 16'h4e89;
        sine_lut[28] = 16'h50ef; sine_lut[29] = 16'h5348; sine_lut[30] = 16'h5591; sine_lut[31] = 16'h57ca;
        sine_lut[32] = 16'h59f3; sine_lut[33] = 16'h5c0b; sine_lut[34] = 16'h5e11; sine_lut[35] = 16'h6006;
        sine_lut[36] = 16'h61e9; sine_lut[37] = 16'h63ba; sine_lut[38] = 16'h6578; sine_lut[39] = 16'h6723;
        sine_lut[40] = 16'h68ba; sine_lut[41] = 16'h6a3d; sine_lut[42] = 16'h6bac; sine_lut[43] = 16'h6d07;
        sine_lut[44] = 16'h6e4c; sine_lut[45] = 16'h6f7d; sine_lut[46] = 16'h709a; sine_lut[47] = 16'h71a2;
        sine_lut[48] = 16'h7293; sine_lut[49] = 16'h736e; sine_lut[50] = 16'h7432; sine_lut[51] = 16'h74de;
        sine_lut[52] = 16'h7572; sine_lut[53] = 16'h75ed; sine_lut[54] = 16'h764f; sine_lut[55] = 16'h7699;
        sine_lut[56] = 16'h76ca; sine_lut[57] = 16'h76e2; sine_lut[58] = 16'h76e2; sine_lut[59] = 16'h76ca;
        sine_lut[60] = 16'h7699; sine_lut[61] = 16'h764f; sine_lut[62] = 16'h75ed; sine_lut[63] = 16'h7572;
        sine_lut[64] = 16'h74de; sine_lut[65] = 16'h7432; sine_lut[66] = 16'h736e; sine_lut[67] = 16'h7293;
        sine_lut[68] = 16'h71a2; sine_lut[69] = 16'h709a; sine_lut[70] = 16'h6f7d; sine_lut[71] = 16'h6e4c;
        sine_lut[72] = 16'h6d07; sine_lut[73] = 16'h6bac; sine_lut[74] = 16'h6a3d; sine_lut[75] = 16'h68ba;
        sine_lut[76] = 16'h6723; sine_lut[77] = 16'h6578; sine_lut[78] = 16'h63ba; sine_lut[79] = 16'h61e9;
        sine_lut[80] = 16'h6006; sine_lut[81] = 16'h5e11; sine_lut[82] = 16'h5c0b; sine_lut[83] = 16'h59f3;
        sine_lut[84] = 16'h57ca; sine_lut[85] = 16'h5591; sine_lut[86] = 16'h5348; sine_lut[87] = 16'h50ef;
        sine_lut[88] = 16'h4e89; sine_lut[89] = 16'h4c14; sine_lut[90] = 16'h4993; sine_lut[91] = 16'h4705;
        sine_lut[92] = 16'h446a; sine_lut[93] = 16'h41c2; sine_lut[94] = 16'h3f11; sine_lut[95] = 16'h3c54;
        sine_lut[96] = 16'h398c; sine_lut[97] = 16'h36ba; sine_lut[98] = 16'h33de; sine_lut[99] = 16'h30fb;
        sine_lut[100] = 16'h2e11; sine_lut[101] = 16'h2b1f; sine_lut[102] = 16'h2827; sine_lut[103] = 16'h2528;
        sine_lut[104] = 16'h2223; sine_lut[105] = 16'h1f1a; sine_lut[106] = 16'h1c0b; sine_lut[107] = 16'h18f8;
        sine_lut[108] = 16'h15e3; sine_lut[109] = 16'h12c8; sine_lut[110] = 16'h0fab; sine_lut[111] = 16'h0c8b;
        sine_lut[112] = 16'h096a; sine_lut[113] = 16'h0647; sine_lut[114] = 16'h0324; sine_lut[115] = 16'h0000;
        sine_lut[116] = 16'hfcdc; sine_lut[117] = 16'hf9b9; sine_lut[118] = 16'hf696; sine_lut[119] = 16'hf375;
        sine_lut[120] = 16'hf055; sine_lut[121] = 16'hed38; sine_lut[122] = 16'hea1d; sine_lut[123] = 16'he709;
        sine_lut[124] = 16'he3f5; sine_lut[125] = 16'he0e6; sine_lut[126] = 16'hdede; sine_lut[127] = 16'hbad8;
        sine_lut[128] = 16'ha7d8; sine_lut[129] = 16'ha4e1; sine_lut[130] = 16'ha1ef; sine_lut[131] = 16'h9f05;
        sine_lut[132] = 16'h9c22; sine_lut[133] = 16'h9946; sine_lut[134] = 16'h9674; sine_lut[135] = 16'h93ac;
        sine_lut[136] = 16'h90f0; sine_lut[137] = 16'h8e3e; sine_lut[138] = 16'h8b96; sine_lut[139] = 16'h88fb;
        sine_lut[140] = 16'h866d; sine_lut[141] = 16'h83ec; sine_lut[142] = 16'h8177; sine_lut[143] = 16'h7f11;
        sine_lut[144] = 16'h7cb8; sine_lut[145] = 16'h7a6f; sine_lut[146] = 16'h7836; sine_lut[147] = 16'h760d;
        sine_lut[148] = 16'h73f5; sine_lut[149] = 16'h71f0; sine_lut[150] = 16'h6ffa; sine_lut[151] = 16'h6e17;
        sine_lut[152] = 16'h6c46; sine_lut[153] = 16'h6a88; sine_lut[154] = 16'h68dc; sine_lut[155] = 16'h6746;
        sine_lut[156] = 16'h65c3; sine_lut[157] = 16'h6454; sine_lut[158] = 16'h62f9; sine_lut[159] = 16'h61b4;
        sine_lut[160] = 16'h6083; sine_lut[161] = 16'h5f66; sine_lut[162] = 16'h5e5e; sine_lut[163] = 16'h5d6d;
        sine_lut[164] = 16'h5c92; sine_lut[165] = 16'h5bc9; sine_lut[166] = 16'h5b22; sine_lut[167] = 16'h5a8e;
        sine_lut[168] = 16'h5a13; sine_lut[169] = 16'h59b1; sine_lut[170] = 16'h5967; sine_lut[171] = 16'h5936;
        sine_lut[172] = 16'h591e; sine_lut[173] = 16'h591e; sine_lut[174] = 16'h5936; sine_lut[175] = 16'h5967;
        sine_lut[176] = 16'h59b1; sine_lut[177] = 16'h5a13; sine_lut[178] = 16'h5a8e; sine_lut[179] = 16'h5b22;
        sine_lut[180] = 16'h5bc9; sine_lut[181] = 16'h5c92; sine_lut[182] = 16'h5d6d; sine_lut[183] = 16'h5e5e;
        sine_lut[184] = 16'h5f66; sine_lut[185] = 16'h6083; sine_lut[186] = 16'h61b4; sine_lut[187] = 16'h62f9;
        sine_lut[188] = 16'h6454; sine_lut[189] = 16'h65c3; sine_lut[190] = 16'h6746; sine_lut[191] = 16'h68dc;
        sine_lut[192] = 16'h6a88; sine_lut[193] = 16'h6c46; sine_lut[194] = 16'h6e17; sine_lut[195] = 16'h6ffa;
        sine_lut[196] = 16'h71f0; sine_lut[197] = 16'h73f5; sine_lut[198] = 16'h760d; sine_lut[199] = 16'h7836;
        sine_lut[200] = 16'h7a6f; sine_lut[201] = 16'h7cb8; sine_lut[202] = 16'h7f11; sine_lut[203] = 16'h8177;
        sine_lut[204] = 16'h83ec; sine_lut[205] = 16'h866d; sine_lut[206] = 16'h88fb; sine_lut[207] = 16'h8b96;
        sine_lut[208] = 16'h8e3e; sine_lut[209] = 16'h90f0; sine_lut[210] = 16'h93ac; sine_lut[211] = 16'h9674;
        sine_lut[212] = 16'h9946; sine_lut[213] = 16'h9c22; sine_lut[214] = 16'h9f05; sine_lut[215] = 16'ha1ef;
        sine_lut[216] = 16'ha4e1; sine_lut[217] = 16'ha7d8; sine_lut[218] = 16'hbad8; sine_lut[219] = 16'hdede;
        sine_lut[220] = 16'he0e6; sine_lut[221] = 16'he3f5; sine_lut[222] = 16'he709; sine_lut[223] = 16'hea1d;
        sine_lut[224] = 16'hed38; sine_lut[225] = 16'hf055; sine_lut[226] = 16'hf375; sine_lut[227] = 16'hf696;
        sine_lut[228] = 16'hf9b9; sine_lut[229] = 16'hfcdc; sine_lut[230] = 16'h0000; sine_lut[231] = 16'h0324;
        sine_lut[232] = 16'h0647; sine_lut[233] = 16'h096a; sine_lut[234] = 16'h0c8b; sine_lut[235] = 16'h0fab;
        sine_lut[236] = 16'h12c8; sine_lut[237] = 16'h15e3; sine_lut[238] = 16'h18f8; sine_lut[239] = 16'h1c0b;
        sine_lut[240] = 16'h1f1a; sine_lut[241] = 16'h2223; sine_lut[242] = 16'h2528; sine_lut[243] = 16'h2827;
        sine_lut[244] = 16'h2b1f; sine_lut[245] = 16'h2e11; sine_lut[246] = 16'h30fb; sine_lut[247] = 16'h33de;
        sine_lut[248] = 16'h36ba; sine_lut[249] = 16'h398c; sine_lut[250] = 16'h3c54; sine_lut[251] = 16'h3f11;
        sine_lut[252] = 16'h41c2; sine_lut[253] = 16'h446a; sine_lut[254] = 16'h4705; sine_lut[255] = 16'h4993;
    end

    // Note Duration Counter: 250 ms = 25,000,000 cycles @ 100 MHz clock
    logic [24:0] note_duration_cnt;
    logic [2:0]  note_idx;
    logic [31:0] phase_step;

    always_ff @(posedge clk) begin
        if (rst) begin
            note_duration_cnt <= 0;
            note_idx          <= 0;
        end else begin
            if (note_duration_cnt >= 25'd24_999_999) begin
                note_duration_cnt <= 0;
                note_idx          <= note_idx + 1; // Cycle through notes 0 to 7
            end else begin
                note_duration_cnt <= note_duration_cnt + 1;
            end
        end
    end

    // C Major Scale Phase Step Lookup table (Fs = 44.1 kHz)
    always_comb begin
        case (note_idx)
            3'd0: phase_step = 32'd12739343; // C3 (130.81 Hz)
            3'd1: phase_step = 32'd14299723; // D3 (146.83 Hz)
            3'd2: phase_step = 32'd16049969; // E3 (164.81 Hz)
            3'd3: phase_step = 32'd17004383; // F3 (174.61 Hz)
            3'd4: phase_step = 32'd19088522; // G3 (196.00 Hz)
            3'd5: phase_step = 32'd21426140; // A3 (220.00 Hz)
            3'd6: phase_step = 32'd24048766; // B3 (246.94 Hz)
            3'd7: phase_step = 32'd25478686; // C4 (261.63 Hz)
        endcase
    end

    // DDS Sample Clock Generator (~44.1 kHz)
    logic [17:0] sample_clk_cnt;
    logic [31:0] phase_acc;

    always_ff @(posedge clk) begin
        if (rst) begin
            sample_clk_cnt <= 0;
            phase_acc      <= 0;
            sine_out       <= 16'h0000;
        end else begin
            if (sample_clk_cnt >= 18'd2267) begin
                sample_clk_cnt <= 0;
                phase_acc      <= phase_acc + phase_step;
                sine_out       <= sine_lut[phase_acc[31:24]];
            end else begin
                sample_clk_cnt <= sample_clk_cnt + 1;
            end
        end
    end

    assign note_idx_out = note_idx;

endmodule
