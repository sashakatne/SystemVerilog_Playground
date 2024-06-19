module novckgen (
    input  wire CK,       // Clock input
    output wire CK1,      // Clock output 1
    output wire CK1_b,    // Inverted clock output 1
    output wire CK2,      // Clock output 2
    output wire CK2_b     // Inverted clock output 2
);

    wire CK_b;
    wire nand1_out, nand2_out;
    wire delay1_out, delay2_out;

    // Invert the clock signal
    not u_not1 (CK_b, CK);

    // NAND gate 1
    nand u_nand1 (nand1_out, CK, delay2_out);

    // NAND gate 2
    nand u_nand2 (nand2_out, CK_b, delay1_out);

    // Delay chain 1 (6 buffers)
    buf u_buf1_a (delay1_out_a, nand1_out);
    buf u_buf1_b (delay1_out_b, delay1_out_a);
    buf u_buf1_c (delay1_out_c, delay1_out_b);
    buf u_buf1_d (delay1_out_d, delay1_out_c);
    buf u_buf1_e (delay1_out_e, delay1_out_d);
    buf u_buf1_f (delay1_out, delay1_out_e);

    // Delay chain 2 (6 buffers)
    buf u_buf2_a (delay2_out_a, nand2_out);
    buf u_buf2_b (delay2_out_b, delay2_out_a);
    buf u_buf2_c (delay2_out_c, delay2_out_b);
    buf u_buf2_d (delay2_out_d, delay2_out_c);
    buf u_buf2_e (delay2_out_e, delay2_out_d);
    buf u_buf2_f (delay2_out, delay2_out_e);

    // Buffers for clock outputs
    buf u_buf3 (CK1, delay1_out);
    not u_not2 (CK1_b, delay1_out);
    buf u_buf4 (CK2, delay2_out);
    not u_not3 (CK2_b, delay2_out);

endmodule
