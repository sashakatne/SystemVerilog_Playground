// Dataflow (behavioural) model of the line-following robot controller.
// Sensors[4:0] = {S4,S3,S2,S1,S0}; 1 = dark line under sensor, 0 = light reflected.
// ML, MR drive the left and right wheel motors (both on = forward; only ML = turn right;
// only MR = turn left; neither = halt). InMotion lights an LED whenever a motor is on.
// Error halts the robot when the line is lost (all zeros) or appears split (non-contiguous 1s).
//
// ML and MR are expressed as minimal sum-of-products; InMotion and Error are direct
// derivations (= ML|MR and its complement) — see design.md for the truth table and the
// Quine-McCluskey derivation that produced each product term.

module RobotController(Sensors, ML, MR, InMotion, Error);

	input [4:0] Sensors;
	output ML, MR, InMotion, Error;

	// Minimal SOP for ML: 5 essential prime implicants covering the 12 minterms
	// {1,2,3,4,6,7,12,14,15,28,30,31}.
	assign ML =  (Sensors[3] &  Sensors[2] &  Sensors[1])
	          | (~Sensors[4] &  Sensors[2] & ~Sensors[0])
	          |  (Sensors[3] &  Sensors[2] & ~Sensors[0])
	          | (~Sensors[4] & ~Sensors[3] &  Sensors[1])
	          | (~Sensors[4] & ~Sensors[3] & ~Sensors[2] & Sensors[0]);

	// Minimal SOP for MR: 5 essential prime implicants covering the 12 minterms
	// {4,6,7,8,12,14,15,16,24,28,30,31}.
	assign MR = (~Sensors[4] &  Sensors[2] &  Sensors[1])
	          |  (Sensors[3] &  Sensors[2] &  Sensors[1])
	          | (~Sensors[4] &  Sensors[2] & ~Sensors[0])
	          |  (Sensors[3] & ~Sensors[1] & ~Sensors[0])
	          |  (Sensors[4] & ~Sensors[2] & ~Sensors[1] & ~Sensors[0]);

	assign InMotion = ML | MR;
	assign Error    = ~InMotion;

endmodule
