module ArbiterCell(r,Cin,g,Cout);

	input r,Cin;
	output g,Cout;
	wire rbar;

	not
		u1a(rbar,r);
	and
		u2a(g,Cin,r),
		u2b(Cout,rbar,Cin);

endmodule
