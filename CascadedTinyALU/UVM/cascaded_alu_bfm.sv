interface cascaded_alu_bfm;
	import cascaded_alu_pkg::*;

	// Interface signals
	logic clk, rst;
	logic start_op;
	logic [DATA_WIDTH-1:0] A, B;
	logic [2:0] op_sel;
	logic [RESULT_WIDTH-1:0] result;
	logic end_op;

	// Clock Generation for Write and Read domains
	initial begin
		clk = '0;
		forever begin
			#(CYCLE_TIME/2) clk = ~clk;
		end
	end

	// Reset uses the slower, read clock
	task reset_cascaded_alu();
	    @(negedge clk);
	    rst = '1;
	    @(negedge clk);
	    start_op = '0;
	    @(posedge clk);
	    rst = '0;
	endtask : reset_cascaded_alu

	// Reset uses the slower, read clock
	task reset_formulop_cascaded_alu();
	    repeat(2) @(negedge clk);
	    rst = '1;
	    @(negedge clk);
	    start_op = '0;
	    @(posedge clk);
	    rst = '0;
	endtask : reset_formulop_cascaded_alu

endinterface


