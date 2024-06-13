// Pipeline implementation of a FFO32

module FFO32p(clock, b, v, p);

    input clock;
    input [0:31] b;
    output v;
    output [0:4] p;

    // Intermediate signals for the outputs of the LZD instances
    wire [0:15] v2;
    wire [0:15] p2;
    // Intermediate pipeline registers for the LZD2 stage
    reg [0:15] v2_reg;
    reg [0:15] p2_reg;
    // Intermediate signals for the outputs of the LZD4 instances
    wire [0:7] v4;
    wire [0:15] p4;
    // Intermediate pipeline registers for the LZD4 stage
    reg [0:7] v4_reg;
    reg [0:15] p4_reg;
    // Intermediate signals for the outputs of the LZD8 instances
    wire [0:3] v8;
    wire [0:11] p8;
    // Intermediate pipeline registers for the LZD8 stage
    reg [0:3] v8_reg;
    reg [0:11] p8_reg;
    // Intermediate signals for the outputs of the LZD16 instances
    wire [0:1] v16;
    wire [0:7] p16;
    // Intermediate pipeline registers for the LZD16 stage
    reg [0:1] v16_reg;
    reg [0:7] p16_reg;

    // Final output signals for the LZD32 instance
    wire v32;
    wire [0:4] p32;
    // Intermediate pipeline registers for the LZD32 stage
    reg v32_reg;
    reg [0:4] p32_reg;

    // Instantiate the 16 LZD2 modules using a for loop
    genvar i;

    generate
        for (i = 0; i < 16; i++) begin : lzd2_gen
            LZD2 lzd2_inst(b[2*i +: 2], v2[i], p2[i]);
        end
    endgenerate
    // Instantiate the 8 LZD4 modules using a for loop
    generate
        for (i = 0; i < 8; i++) begin : lzd4_gen
            LZDn #(4) lzd4_inst(v2_reg[2*i], v2_reg[2*i+1], p2_reg[2*i], p2_reg[2*i+1], v4[i], p4[2*i +: 2]);
        end
    endgenerate
    // Instantiate the 4 LZD8 modules using a for loop
    generate
        for (i = 0; i < 4; i++) begin : lzd8_gen
            LZDn #(8) lzd8_inst(v4_reg[2*i], v4_reg[2*i+1], p4_reg[4*i +: 2], p4_reg[4*i+2 +: 2], v8[i], p8[3*i +: 3]);
        end
    endgenerate
    // Instantiate the 2 LZD16 modules using a for loop
    generate
        for (i = 0; i < 2; i++) begin : lzd16_gen
            LZDn #(16) lzd16_inst(v8_reg[2*i], v8_reg[2*i+1], p8_reg[6*i +: 3], p8_reg[6*i+3 +: 3], v16[i], p16[4*i +: 4]);
        end
    endgenerate

    // Instantiate the single LZD32 module to finalize the FFO32 output
    LZDn #(32) lzd32_inst(v16_reg[0], v16_reg[1], p16_reg[0 +: 4], p16_reg[4 +: 4], v32, p32);

    assign p = p32_reg;
    assign v = v32_reg;

    always @(posedge clock) begin

        // Capture the LZD2 stage results
        v2_reg <= v2;
        p2_reg <= p2;

        // Capture the LZD4 stage results
        v4_reg <= v4;
        p4_reg <= p4;

        // Capture the LZD8 stage results
        v8_reg <= v8;
        p8_reg <= p8;

        // Capture the LZD16 stage results
        v16_reg <= v16;
        p16_reg <= p16;

        // Capture the LZD32 stage results
        v32_reg <= v32;
        p32_reg <= p32;

    end

endmodule

module LZD2(input logic [0:1] b, output logic v, output logic p);

    assign v = b[0] | b[1];
    assign p = ~b[0];
    
endmodule

module LZDn(v0, v1, p0, p1, v, p);

    parameter n = 32;
    input v0, v1;
    input [0:$clog2(n)-2] p0, p1;
    output v;
    output [0:$clog2(n)-1] p;

    assign v = v0 | v1;
    assign p = v0 ? {1'b0, p0} : {1'b1, p1};

endmodule
