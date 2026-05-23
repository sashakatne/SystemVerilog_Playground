// N-bit 2:1 multiplexer, dataflow style.
// Y = Sel ? B : A
module Mux2to1 #(parameter int N = 32) (
    input  logic [N-1:0] A,
    input  logic [N-1:0] B,
    input  logic         Sel,
    output logic [N-1:0] Y
);

    assign Y = Sel ? B : A;

endmodule


// N-bit left-shift barrel shifter built from $clog2(N) stages of N-bit 2:1
// muxes. Stage k (counting from the MSB end of ShiftAmount) either passes its
// input through or shifts it left by 2**(STAGES-1-k), with ShiftIn replicated
// into the vacated LSB positions. ShiftAmount[STAGES-1] controls the largest
// shift (by N/2), matching the description in the spec.
module BarrelShifter #(parameter int N = 32) (
    input  logic [N-1:0]              In,
    input  logic [$clog2(N)-1:0]      ShiftAmount,
    input  logic                       ShiftIn,
    output logic [N-1:0]               Out
);

    localparam int STAGES = $clog2(N);

    logic [N-1:0] stage [0:STAGES];
    assign stage[0] = In;

    genvar k;
    generate
        for (k = 0; k < STAGES; k++) begin : g_stage
            localparam int SHIFT = 1 << (STAGES - 1 - k);
            logic [N-1:0] shifted;
            assign shifted = {stage[k][N-1-SHIFT:0], {SHIFT{ShiftIn}}};
            Mux2to1 #(.N(N)) u_mux (
                .A   (stage[k]),
                .B   (shifted),
                .Sel (ShiftAmount[STAGES-1-k]),
                .Y   (stage[k+1])
            );
        end
    endgenerate

    assign Out = stage[STAGES];

endmodule
