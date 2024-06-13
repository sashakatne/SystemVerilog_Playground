// Known Good Device for Arbiter4 self checking testbench

module KGD(r,g);

	input [0:3]r;
	output reg [0:3]g;

	always @(r)

		case (r)
			0: g = 4'b0000;
			1: g = 4'b0001;
			2: g = 4'b0010;
			3: g = 4'b0010;
			4: g = 4'b0100;
			5: g = 4'b0100;
			6: g = 4'b0100;
			7: g = 4'b0100;
			8: g = 4'b1000;
			9: g = 4'b1000;
			10: g = 4'b1000;
			11: g = 4'b1000;
			12: g = 4'b1000;
			13: g = 4'b1000;
			14: g = 4'b1000;
			15: g = 4'b1000;
		endcase

endmodule

module top();

	localparam DELAY = 1;
	reg [0:3]r;
	wire [0:3]g0;
	wire [0:3]g;
	reg Errors;
	integer i;

	KGD KGD0(r,g0);
	Arbiter4 arbiter4(r,g);

	initial begin
		Errors = 0;
		for (i = 0; i < 16; i = i+1) begin
			r = i;
			#(DELAY);
			if (g !== g0) begin
				$display("*** Error: r = %b, expecting g = %b, got %b",r,g0,g);
				Errors = 1;
			end
		end

	if (Errors == 0)
		$display("No errors -- passed testbench");
	else
		$display("Failed testbench");
	end

endmodule

