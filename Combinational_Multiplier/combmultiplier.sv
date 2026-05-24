module full_adder(a, b, cin, sum, cout);

    input  wire a;        // First input bit
    input  wire b;        // Second input bit
    input  wire cin;      // Carry-in bit
    output wire sum;      // Sum output bit
    output wire cout;      // Carry-out bit
    // The sum is the XOR of the three inputs
    assign sum = a ^ b ^ cin;
    // The carry-out is true if any two or more inputs are true
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule

module multiplier_cell(m, q, pp_in, carry_in, pp_out, carry_out, m_out, q_out);

    input  wire m;        // Multiplicand bit
    input  wire q;        // Multiplier bit
    input  wire pp_in;    // Bit of incoming partial product
    input  wire carry_in; // Carry-in from the previous cell
    output wire pp_out;   // Bit of outgoing partial product
    output wire carry_out;// Carry-out to the next cell
    output wire m_out;    // Multiplicand bit for next cell
    output wire q_out;     // Multiplier bit for next cell

    // Pass through the multiplicand and multiplier bits
    assign m_out = m;
    assign q_out = q;

    // Generate partial product
    wire partial_product;
    assign partial_product = m & q;

    // Full adder for summing partial products and carry
    wire sum, co;
    full_adder fa(pp_in, partial_product, carry_in, sum, co);

    assign pp_out = sum;
    assign carry_out = co;

endmodule

module NxN_multiplier (multiplicand, multiplier, product);

    parameter N = 4;
    input  wire [N-1:0] multiplicand;
    input  wire [N-1:0] multiplier;
    output wire [2*N-1:0] product;

    wire [N-1:0] pp [N-1:0]; // Partial products
    wire [N-1:0] carry [N-1:0]; // Carries
    wire [N-1:0] m_out [N-1:0]; // Multiplicand bits for next cells
    wire [N-1:0] q_out [N-1:0]; // Multiplier bits for next cells

    // Generate the NxN grid of multiplier cells.
    // The cell inputs depend on (i, j); ternary selects with i-1 / j-1
    // indices triggered vopt-2576/2696 BSOB warnings on row 0 / column 0
    // even though those branches are never live. The generate-if structure
    // below picks the right wire per (i, j) tile, so the out-of-range
    // references never elaborate.
    genvar i, j, k;
    generate
        for (i = 0; i < N; i++) begin : rows
            for (j = 0; j < N; j++) begin : cols
                wire m_in, q_in, pp_in_w, carry_in_w;

                if (i == 0)
                    assign m_in = multiplicand[j];
                else
                    assign m_in = m_out[i-1][j];

                if (j == 0)
                    assign q_in = multiplier[i];
                else
                    assign q_in = q_out[i][j-1];

                if (i == 0)
                    assign pp_in_w = 1'b0;
                else if (j < N-1)
                    assign pp_in_w = pp[i-1][j+1];
                else
                    assign pp_in_w = carry[i-1][N-1];

                if (j == 0)
                    assign carry_in_w = 1'b0;
                else
                    assign carry_in_w = carry[i][j-1];

                multiplier_cell mc(
                    .m(m_in),
                    .q(q_in),
                    .pp_in(pp_in_w),
                    .carry_in(carry_in_w),
                    .pp_out(pp[i][j]),
                    .carry_out(carry[i][j]),
                    .m_out(m_out[i][j]),
                    .q_out(q_out[i][j])
                );
            end
        end
    endgenerate

    for (k = 0; k < 2*N; k = k + 1) begin : result_collection
        if (k < N) begin
            assign product[k] = pp[k][0];
        end else if (k < 2*N-1) begin
            assign product[k] = pp[N-1][k-N+1];
        end else begin
            assign product[k] = carry[N-1][N-1];
        end
    end

endmodule
