// Known Good Device for ArbiterN self checking testbench

module KGD(r,g);

	parameter n=8;
	input [0:n-1]r;
	output reg [0:n-1]g;

	integer i;
	reg found;

	always @(r) begin
		g = 0; // Default to all zeros
		found = 0; // Indicates if the highest priority '1' has been found
		for (i = 0; i < n; i = i + 1) begin
			if (r[i] == 1'b1 && found == 0) begin
				g[i] = 1'b1;
				found = 1; // Set found to '1' to indicate the highest priority '1' has been found
			end
		end
	end

endmodule

module top;

	localparam DELAY = 1;
	parameter n=8;
	reg [0:n-1]r;
	wire [0:n-1]g0;
	wire [0:n-1]g;
	integer i;
	reg Errors;

	// Parameterized instantiation of the KGD cell
	KGD #(.n(n)) KGD0(r,g0);
	// Parameterized instantiation of the ArbiterN cell
	ArbiterN #(.n(n)) DUT(r,g);

	initial begin
		Errors = 0;
		for (i = 0; i < (1 <<n) ; i = i+1) begin
			r = i;
			#(DELAY);
			if (g !== g0) begin
				$display("*** Error: r = %d, expecting g = %b, got %b",r,g0,g);
				Errors = 1;
			end
		end
			  
		if (Errors == 0)
			$display("No errors -- passed testbench");
		else
			$display("Failed testbench");
	end

endmodule
