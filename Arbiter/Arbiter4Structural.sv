
module Arbiter4(r,g);

	input [0:3]r;
	output[0:3]g;
	wire [0:3]c;

	ArbiterCell A0(r[0],1'b1,g[0],c[1]); //First cell gets carry-in of 1 due to highest priority
	ArbiterCell A1(r[1],c[1],g[1],c[2]);
	ArbiterCell A2(r[2],c[2],g[2],c[3]);
	ArbiterCell A3(r[3],c[3],g[3],);     //Note that the carry-out of the last arbiter cell is not necessary to be defined

endmodule