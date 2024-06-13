// Known Good Device for ArbiterCell self checking testbench

module KGD(r,Cin,g,Cout);

	input r,Cin;
	output reg g,Cout;

	always @(r or Cin)

		case ({r,Cin})
			0: {g,Cout} = 2'b00;
			1: {g,Cout} = 2'b01;
			2: {g,Cout} = 2'b00;
			3: {g,Cout} = 2'b10;
		endcase

endmodule

module top();

	localparam DELAY = 1;
	reg r,Cin;
	wire g0,Cout0;
	wire g,Cout;
	reg Errors;
	integer i;

	KGD KGD0(r,Cin,g0,Cout0);
	ArbiterCell arbiter(r,Cin,g,Cout);

	initial begin
		Errors = 0;
		for(i = 0; i < 4; i = i+1) begin
			{r,Cin} = i;
			#(DELAY);
			if ({g,Cout} !== {g0,Cout0}) begin
				$display("*** Error: r = %b, expecting {g,Cout} = %b, got %b",r,{g0,Cout0},{g,Cout});
				Errors = 1;
			end
		end

	if (Errors == 0)
		$display("No errors -- passed testbench");
	else
		$display("Failed testbench");
	end

endmodule

