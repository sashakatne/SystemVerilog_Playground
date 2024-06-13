module ArbiterN(r,g);

	parameter n=8;
	input [0:n-1]r;
	output [0:n-1]g;
	
	wire [0:n]c;
	genvar i;
	assign c[0]=1'b1; //First cell gets carry-in of 1 due to highest priority
	
	generate
		for(i=0;i<n;i=i+1) begin:Arbiter
			ArbiterCell An (r[i],c[i],g[i],c[i+1]);
		end
	endgenerate
	
	//Note that the carry-out of the last arbiter cell is not necessary to be defined
	
endmodule