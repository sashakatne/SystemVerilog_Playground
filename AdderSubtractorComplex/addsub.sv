module AddSub8Bit #(parameter int N = 8) (result, x, y, ccn, ccz, ccv, ccc, sub);
    input  logic [N-1:0] x, y;
    output logic [N-1:0] result;
    output logic ccn, ccz, ccv, ccc;
    input  logic sub;

    logic [N-1:0] y_effective;
    logic [N:0] carry;

    assign y_effective = y ^ {N{sub}};
    assign carry[0] = sub;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : g_adder
            FullAdder u_fulladder (
                .sum  (result[i]),
                .cout (carry[i+1]),
                .a    (x[i]),
                .b    (y_effective[i]),
                .cin  (carry[i])
            );
        end
    endgenerate

    assign ccn = result[N-1];
    assign ccz = (result == '0);
    assign ccv = carry[N-1] ^ carry[N];
    assign ccc = carry[N];

endmodule
