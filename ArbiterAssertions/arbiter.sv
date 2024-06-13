module Arbiter(clock, reset, r, g);
    input clock, reset;
    input [0:7]  r;
    output logic [0:7] g;

    logic [0:7] g_out;

    ArbiterN #(.n(8)) arbitern (.r(r), .g(g_out));
    always_ff @(posedge clock) begin
        if (reset) begin
            g <= '0;
        end else begin
            g <= g_out;
        end
    end
endmodule

module ArbiterN(r,g);
    parameter n = 8;
    input [0:n-1] r;
    output [0:n-1] g;
    wire [0:n] c;
    genvar i;
    assign c[0] = '1;
    generate
        for(i = 0; i < n; i = i + 1) begin:Arbiter
            ArbiterCell arbitercell (r[i],c[i],g[i],c[i+1]);
        end
	endgenerate	
endmodule

module ArbiterCell(r,Cin,g,Cout);
    input r, Cin;
    output g, Cout;
    wire rbar;
    not
        u1a(rbar,r);
    and
        u2a(g, Cin, r),
        u2b(Cout, rbar, Cin);
endmodule
