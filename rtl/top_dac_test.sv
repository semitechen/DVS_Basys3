`timescale 1ns / 1ps

module top_dac_test (
    input  logic clk,
    input  logic btnC,
    output logic [15:0] led,
    output logic JA1
);

    logic [15:0] sine_lut [0:255];
    initial begin
        sine_lut[0] = 16'h8000; sine_lut[1] = 16'h8324; sine_lut[2] = 16'h8647; sine_lut[3] = 16'h896a;
        sine_lut[4] = 16'h8c8b; sine_lut[5] = 16'h8fab; sine_lut[6] = 16'h92c8; sine_lut[7] = 16'h95e3;
        sine_lut[8] = 16'h98f8; sine_lut[9] = 16'h9c0b; sine_lut[10] = 16'h9f1a; sine_lut[11] = 16'ha223;
        sine_lut[12] = 16'ha528; sine_lut[13] = 16'ha827; sine_lut[14] = 16'hab1f; sine_lut[15] = 16'hae11;
        sine_lut[16] = 16'hb0fb; sine_lut[17] = 16'hb3de; sine_lut[18] = 16'hb6ba; sine_lut[19] = 16'hb98c;
        sine_lut[20] = 16'hbc54; sine_lut[21] = 16'hbf11; sine_lut[22] = 16'hc1c2; sine_lut[23] = 16'hc46a;
        sine_lut[24] = 16'hc705; sine_lut[25] = 16'hc993; sine_lut[26] = 16'hcc14; sine_lut[27] = 16'hce89;
        sine_lut[28] = 16'hd0ef; sine_lut[29] = 16'hd348; sine_lut[30] = 16'hd591; sine_lut[31] = 16'hd7ca;
        sine_lut[32] = 16'hd9f3; sine_lut[33] = 16'hdc0b; sine_lut[34] = 16'hde11; sine_lut[35] = 16'he006;
        sine_lut[36] = 16'he1e9; sine_lut[37] = 16'he3ba; sine_lut[38] = 16'he578; sine_lut[39] = 16'he723;
        sine_lut[40] = 16'he8ba; sine_lut[41] = 16'hea3d; sine_lut[42] = 16'hebac; sine_lut[43] = 16'hed07;
        sine_lut[44] = 16'hee4c; sine_lut[45] = 16'hef7d; sine_lut[46] = 16'hf09a; sine_lut[47] = 16'hf1a2;
        sine_lut[48] = 16'hf293; sine_lut[49] = 16'hf36e; sine_lut[50] = 16'hf432; sine_lut[51] = 16'hf4de;
        sine_lut[52] = 16'hf572; sine_lut[53] = 16'hf5ed; sine_lut[54] = 16'hf64f; sine_lut[55] = 16'hf699;
        sine_lut[56] = 16'hf6ca; sine_lut[57] = 16'hf6e2; sine_lut[58] = 16'hf6e2; sine_lut[59] = 16'hf6ca;
        sine_lut[60] = 16'hf699; sine_lut[61] = 16'hf64f; sine_lut[62] = 16'hf5ed; sine_lut[63] = 16'hf572;
        sine_lut[64] = 16'hf4de; sine_lut[65] = 16'hf432; sine_lut[66] = 16'hf36e; sine_lut[67] = 16'hf293;
        sine_lut[68] = 16'hf1a2; sine_lut[69] = 16'hf09a; sine_lut[70] = 16'hef7d; sine_lut[71] = 16'hee4c;
        sine_lut[72] = 16'hed07; sine_lut[73] = 16'hebac; sine_lut[74] = 16'hea3d; sine_lut[75] = 16'he8ba;
        sine_lut[76] = 16'he723; sine_lut[77] = 16'he578; sine_lut[78] = 16'he3ba; sine_lut[79] = 16'he1e9;
        sine_lut[80] = 16'he006; sine_lut[81] = 16'hde11; sine_lut[82] = 16'hdc0b; sine_lut[83] = 16'hd9f3;
        sine_lut[84] = 16'hd7ca; sine_lut[85] = 16'hd591; sine_lut[86] = 16'hd348; sine_lut[87] = 16'hd0ef;
        sine_lut[88] = 16'hce89; sine_lut[89] = 16'hcc14; sine_lut[90] = 16'hc993; sine_lut[91] = 16'hc705;
        sine_lut[92] = 16'hc46a; sine_lut[93] = 16'hc1c2; sine_lut[94] = 16'hbf11; sine_lut[95] = 16'hbc54;
        sine_lut[96] = 16'hb98c; sine_lut[97] = 16'hb6ba; sine_lut[98] = 16'hb3de; sine_lut[99] = 16'hb0fb;
        sine_lut[100] = 16'hae11; sine_lut[101] = 16'hab1f; sine_lut[102] = 16'ha827; sine_lut[103] = 16'ha528;
        sine_lut[104] = 16'ha223; sine_lut[105] = 16'h9f1a; sine_lut[106] = 16'h9c0b; sine_lut[107] = 16'h98f8;
        sine_lut[108] = 16'h95e3; sine_lut[109] = 16'h92c8; sine_lut[110] = 16'h8fab; sine_lut[111] = 16'h8c8b;
        sine_lut[112] = 16'h896a; sine_lut[113] = 16'h8647; sine_lut[114] = 16'h8324; sine_lut[115] = 16'h8000;
        sine_lut[116] = 16'h7cdb; sine_lut[117] = 16'h79b8; sine_lut[118] = 16'h7695; sine_lut[119] = 16'h7374;
        sine_lut[120] = 16'h7054; sine_lut[121] = 16'h6d37; sine_lut[122] = 16'h6a1c; sine_lut[123] = 16'h6707;
        sine_lut[124] = 16'h63f4; sine_lut[125] = 16'h60e5; sine_lut[126] = 16'h5ddd; sine_lut[127] = 16'h5ad7;
        sine_lut[128] = 16'h57d8; sine_lut[129] = 16'h54e0; sine_lut[130] = 16'h51ee; sine_lut[131] = 16'h4f04;
        sine_lut[132] = 16'h4c21; sine_lut[133] = 16'h4945; sine_lut[134] = 16'h4673; sine_lut[135] = 16'h43ab;
        sine_lut[136] = 16'h40ef; sine_lut[137] = 16'h3e3d; sine_lut[138] = 16'h3b95; sine_lut[139] = 16'h38fa;
        sine_lut[140] = 16'h366c; sine_lut[141] = 16'h33eb; sine_lut[142] = 16'h3176; sine_lut[143] = 16'h2f10;
        sine_lut[144] = 16'h2cb7; sine_lut[145] = 16'h2a6e; sine_lut[146] = 16'h2835; sine_lut[147] = 16'h260c;
        sine_lut[148] = 16'h23f4; sine_lut[149] = 16'h21ef; sine_lut[150] = 16'h1ff9; sine_lut[151] = 16'h1e16;
        sine_lut[152] = 16'h1c45; sine_lut[153] = 16'h1a87; sine_lut[154] = 16'h18db; sine_lut[155] = 16'h1745;
        sine_lut[156] = 16'h15c2; sine_lut[157] = 16'h1453; sine_lut[158] = 16'h12f8; sine_lut[159] = 16'h11b3;
        sine_lut[160] = 16'h1082; sine_lut[161] = 16'h0f65; sine_lut[162] = 16'h0e5d; sine_lut[163] = 16'h0d6c;
        sine_lut[164] = 16'h0c91; sine_lut[165] = 16'h0bc8; sine_lut[166] = 16'h0b21; sine_lut[167] = 16'h0a8d;
        sine_lut[168] = 16'h0a12; sine_lut[169] = 16'h09b0; sine_lut[170] = 16'h0966; sine_lut[171] = 16'h0935;
        sine_lut[172] = 16'h091d; sine_lut[173] = 16'h091d; sine_lut[174] = 16'h0935; sine_lut[175] = 16'h0966;
        sine_lut[176] = 16'h09b0; sine_lut[177] = 16'h0a12; sine_lut[178] = 16'h0a8d; sine_lut[179] = 16'h0b21;
        sine_lut[180] = 16'h0bc8; sine_lut[181] = 16'h0c91; sine_lut[182] = 16'h0d6c; sine_lut[183] = 16'h0e5d;
        sine_lut[184] = 16'h0f65; sine_lut[185] = 16'h1082; sine_lut[186] = 16'h11b3; sine_lut[187] = 16'h12f8;
        sine_lut[188] = 16'h1453; sine_lut[189] = 16'h15c2; sine_lut[190] = 16'h1745; sine_lut[191] = 16'h18db;
        sine_lut[192] = 16'h1a87; sine_lut[193] = 16'h1c45; sine_lut[194] = 16'h1e16; sine_lut[195] = 16'h1ff9;
        sine_lut[196] = 16'h21ef; sine_lut[197] = 16'h23f4; sine_lut[198] = 16'h260c; sine_lut[199] = 16'h2835;
        sine_lut[200] = 16'h2a6e; sine_lut[201] = 16'h2cb7; sine_lut[202] = 16'h2f10; sine_lut[203] = 16'h3176;
        sine_lut[204] = 16'h33eb; sine_lut[205] = 16'h366c; sine_lut[206] = 16'h38fa; sine_lut[207] = 16'h3b95;
        sine_lut[208] = 16'h3e3d; sine_lut[209] = 16'h40ef; sine_lut[210] = 16'h43ab; sine_lut[211] = 16'h4673;
        sine_lut[212] = 16'h4945; sine_lut[213] = 16'h4c21; sine_lut[214] = 16'h4f04; sine_lut[215] = 16'h51ee;
        sine_lut[216] = 16'h54e0; sine_lut[217] = 16'h57d8; sine_lut[218] = 16'h5ad7; sine_lut[219] = 16'h5ddd;
        sine_lut[220] = 16'h60e5; sine_lut[221] = 16'h63f4; sine_lut[222] = 16'h6707; sine_lut[223] = 16'h6a1c;
        sine_lut[224] = 16'h6d37; sine_lut[225] = 16'h7054; sine_lut[226] = 16'h7374; sine_lut[227] = 16'h7695;
        sine_lut[228] = 16'h79b8; sine_lut[229] = 16'h7cdb; sine_lut[230] = 16'h8000; sine_lut[231] = 16'h8324;
        sine_lut[232] = 16'h8647; sine_lut[233] = 16'h896a; sine_lut[234] = 16'h8c8b; sine_lut[235] = 16'h8fab;
        sine_lut[236] = 16'h92c8; sine_lut[237] = 16'h95e3; sine_lut[238] = 16'h98f8; sine_lut[239] = 16'h9c0b;
        sine_lut[240] = 16'h9f1a; sine_lut[241] = 16'ha223; sine_lut[242] = 16'ha528; sine_lut[243] = 16'ha827;
        sine_lut[244] = 16'hab1f; sine_lut[245] = 16'hae11; sine_lut[246] = 16'hb0fb; sine_lut[247] = 16'hb3de;
        sine_lut[248] = 16'hb6ba; sine_lut[249] = 16'hb98c; sine_lut[250] = 16'hbc54; sine_lut[251] = 16'hbf11;
        sine_lut[252] = 16'hc1c2; sine_lut[253] = 16'hc46a; sine_lut[254] = 16'hc705; sine_lut[255] = 16'hc993;
    end

    logic [31:0] phase_acc;
    logic [17:0] slow_clk_cnt;

    always_ff @(posedge clk) begin
        if (btnC) begin
            slow_clk_cnt <= 0;
            phase_acc <= 0;
        end else begin
            if (slow_clk_cnt >= 18'd2267) begin // ~44.1kHz @ 100MHz
                slow_clk_cnt <= 0;
                phase_acc <= phase_acc + 32'd112721921; // ~440Hz: (440 * 2^32) / 44100
            end else begin
                slow_clk_cnt <= slow_clk_cnt + 1;
            end
        end
    end

    logic [15:0] sine_data;
    assign sine_data = sine_lut[phase_acc[31:24]];
    assign led = sine_data;

    ds_dac #(
        .WIDTH(16)
    ) u_ds_dac (
        .clk(clk),
        .rst(btnC),
        .din(sine_data),
        .dout(JA1)
    );

endmodule
