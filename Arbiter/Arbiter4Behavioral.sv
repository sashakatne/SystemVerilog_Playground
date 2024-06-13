module Arbiter4(r,g);

	input [0:3]r;
	output reg [0:3]g;

	always @(r) begin

		g[0]=r[0];
		g[1]=~r[0]&r[1];
		g[2]=~r[0]&~r[1]&r[2];
		g[3]=~r[0]&~r[1]&~r[2]&r[3];

	end
	
endmodule
