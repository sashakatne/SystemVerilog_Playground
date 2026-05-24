// Self-checking testbench for RobotController. Sweeps all 32 sensor patterns and
// compares the DUT outputs against a Known-Good-Device behavioural reference model
// that classifies each pattern as forward / turn-left / turn-right / error.
//
// Reports PASS per vector, prints "*** Error" on any mismatch, and ends with either
// "No errors -- passed testbench" or "Failed testbench" so the playground's transcript-
// based verification gate can confirm correctness from the captured log alone.

`ifndef VCD_FILE
`define VCD_FILE "linefollowing_waveforms.vcd"
`endif

module RobotControllerGolden(Sensors, ML, MR, InMotion, Error);

	input  [4:0] Sensors;
	output reg   ML, MR, InMotion, Error;

	integer k, firstOne, lastOne;
	reg     contiguous;

	always @(Sensors) begin
		firstOne = -1;
		lastOne  = -1;
		for (k = 0; k < 5; k = k + 1) begin
			if (Sensors[k] === 1'b1) begin
				if (firstOne == -1) firstOne = k;
				lastOne = k;
			end
		end

		if (firstOne == -1) begin
			ML = 1'b0; MR = 1'b0; InMotion = 1'b0; Error = 1'b1;
		end else begin
			contiguous = 1'b1;
			for (k = firstOne; k <= lastOne; k = k + 1) begin
				if (Sensors[k] === 1'b0) contiguous = 1'b0;
			end

			if (contiguous == 1'b0) begin
				ML = 1'b0; MR = 1'b0; InMotion = 1'b0; Error = 1'b1;
			end else if (Sensors[2] === 1'b1) begin
				ML = 1'b1; MR = 1'b1; InMotion = 1'b1; Error = 1'b0;
			end else if (lastOne > 2) begin
				ML = 1'b0; MR = 1'b1; InMotion = 1'b1; Error = 1'b0;
			end else begin
				ML = 1'b1; MR = 1'b0; InMotion = 1'b1; Error = 1'b0;
			end
		end
	end

endmodule


module top;

	localparam DELAY = 1;

	reg  [4:0] Sensors;
	wire       ML,  MR,  InMotion,  Error;
	wire       eML, eMR, eInMotion, eError;
	integer    i;
	reg        Errors;
	reg  [3:0] Expected;
	reg        Match;
	reg        Sample;
	integer    CheckIndex;
	integer    CaseCode;

	// Behavioural reference (KGD) — same ports, drives expected outputs.
	RobotControllerGolden REF(
		.Sensors(Sensors), .ML(eML), .MR(eMR), .InMotion(eInMotion), .Error(eError));

	// Design under test — either robotdataflow.sv or robotstructural.sv supplies this module.
	RobotController DUT(
		.Sensors(Sensors), .ML(ML),  .MR(MR),  .InMotion(InMotion),  .Error(Error));

	initial begin
		$dumpfile(`VCD_FILE);
		$dumpvars(0);
	end

	function automatic integer classify_case(
		input [4:0] sensors,
		input       exp_ml,
		input       exp_mr,
		input       exp_error
	);
		if (exp_error) begin
			if (sensors == 5'b00000)
				classify_case = 0; // lost
			else
				classify_case = 1; // split/non-contiguous
		end else if (exp_ml && exp_mr) begin
			classify_case = 2;     // centered/forward
		end else if (!exp_ml && exp_mr) begin
			classify_case = 3;     // line left of center, turn left
		end else begin
			classify_case = 4;     // line right of center, turn right
		end
	endfunction

	initial begin
		Errors = 1'b0;
		Sample = 1'b0;
		Expected = 4'b0000;
		Match = 1'b0;
		CheckIndex = 0;
		CaseCode = 0;

		for (i = 0; i < 32; i = i + 1) begin
			Sensors = i[4:0];
			#(DELAY);
			Expected = {eML, eMR, eInMotion, eError};
			Match = ((ML === eML) && (MR === eMR) && (InMotion === eInMotion) && (Error === eError));
			CheckIndex = i + 1;
			CaseCode = classify_case(Sensors, eML, eMR, eError);
			Sample = 1'b1;
			#(DELAY);
			Sample = 1'b0;

			if (!Match) begin
				$display("*** Error: Sensors = %b, expected ML/MR/InMotion/Error = %b/%b/%b/%b, got %b/%b/%b/%b",
					Sensors, eML, eMR, eInMotion, eError, ML, MR, InMotion, Error);
				Errors = 1'b1;
			end else begin
				$display("PASS: Sensors = %b -> ML=%b MR=%b InMotion=%b Error=%b",
					Sensors, ML, MR, InMotion, Error);
			end
		end

		if (Errors == 1'b0)
			$display("No errors -- passed testbench");
		else
			$display("Failed testbench");

		$finish;
	end

endmodule
