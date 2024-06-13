module FFO32(input logic [0:31] b, output logic v, output logic [0:4] p);

    // Intermediate signals for the outputs of the LZD instances
    logic [0:15] v2;
    logic [0:15] p2;

    // Instantiate the 16 LZD2 modules using a for loop
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : lzd2_gen
            LZD2 lzd2_inst(b[2*i +: 2], v2[i], p2[i]);
        end
    endgenerate

    // Intermediate signals for the outputs of the LZD4 instances
    logic [0:7] v4;
    logic [0:15] p4;

    // Instantiate the 8 LZD4 modules using a for loop
    generate
        for (i = 0; i < 8; i++) begin : lzd4_gen
            LZDn #(4) lzd4_inst(v2[2*i], v2[2*i+1], p2[2*i], p2[2*i+1], v4[i], p4[2*i +: 2]);
        end
    endgenerate

    // Intermediate signals for the outputs of the LZD8 instances
    logic [0:3] v8;
    logic [0:11] p8;

    // Instantiate the 4 LZD8 modules using a for loop
    generate
        for (i = 0; i < 4; i++) begin : lzd8_gen
            LZDn #(8) lzd8_inst(v4[2*i], v4[2*i+1], p4[4*i +: 2], p4[4*i+2 +: 2], v8[i], p8[3*i +: 3]);
        end
    endgenerate

    // Intermediate signals for the outputs of the LZD16 instances
    logic [0:1] v16;
    logic [0:7] p16;

    // Instantiate the 2 LZD16 modules using a for loop
    generate
        for (i = 0; i < 2; i++) begin : lzd16_gen
            LZDn #(16) lzd16_inst(v8[2*i], v8[2*i+1], p8[6*i +: 3], p8[6*i+3 +: 3], v16[i], p16[4*i +: 4]);
        end
    endgenerate

    // Instantiate the single LZD32 module to finalize the FFO32 output
    LZDn #(32) lzd32_inst(v16[0], v16[1], p16[0 +: 4], p16[4 +: 4], v, p);

endmodule

