import pkg::*;

class scoreboard;

	parameter DATA_WIDTH = 16;
	parameter RESULT_WIDTH = 32;
	bit [RESULT_WIDTH-1:0] predicted_result;

	int no_trans;

	mailbox mon2scb;

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction 

	virtual task main();

	begin

		transaction trans_sb;
		mon2scb.get(trans_sb);

		wait(trans_sb.end_op);

		unique case (trans_sb.op_sel)
			3'b000: predicted_result = trans_sb.A * trans_sb.B;
			3'b001: predicted_result = trans_sb.A + trans_sb.B;
			3'b010: predicted_result = trans_sb.A - trans_sb.B;
			3'b011: predicted_result = trans_sb.A + trans_sb.B + 1;
			3'b100: predicted_result = trans_sb.A | trans_sb.B;
			3'b101: predicted_result = trans_sb.A & trans_sb.B;
			3'b110: predicted_result = trans_sb.A ^ trans_sb.B;
			3'b111: predicted_result = {~trans_sb.A, ~trans_sb.B};
		endcase

		if (predicted_result !== trans_sb.result)
		begin
			$display("FAILED: A: %0h  B: %0h  op_sel: %0b got: %0h expected: %0h", trans_sb.A, trans_sb.B, trans_sb.op_sel, trans_sb.result, predicted_result);
		end
		else
		begin
			$display("PASSED: A: %0h  B: %0h  op_sel: %0b got: %0h expected: %0h", trans_sb.A, trans_sb.B, trans_sb.op_sel, trans_sb.result, predicted_result);
		end

		no_trans++;

	end

	endtask

endclass
