module FullAdder(sum, cout, a, b, cin);
    input  logic a, b, cin;
    output logic sum, cout;

    wire axorb;
    wire ab;
    wire axorb_cin;
    wire sum_wire;
    wire cout_wire;

    xor u_xor_ab  (axorb, a, b);
    xor u_xor_sum (sum_wire, axorb, cin);
    and u_and_ab  (ab, a, b);
    and u_and_cin (axorb_cin, axorb, cin);
    or  u_or_cout (cout_wire, ab, axorb_cin);

    assign sum = sum_wire;
    assign cout = cout_wire;

endmodule
