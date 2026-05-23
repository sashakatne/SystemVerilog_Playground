// Structural (gate-primitive) model of the line-following robot controller.
// Implements the same minimal SOP equations as robotdataflow.sv using Verilog gate
// primitives (not, and, or). The two modules are interchangeable from the testbench's
// viewpoint — they share the module name RobotController.
//
// Topology per motor: five AND-of-literals product terms feeding one 5-input OR.
// Five sensor inverters drive the negated literals. InMotion = OR(ML, MR); Error = NOT(InMotion).

module RobotController(Sensors, ML, MR, InMotion, Error);

	input [4:0] Sensors;
	output ML, MR, InMotion, Error;

	wire nS4, nS3, nS2, nS1, nS0;

	wire ml_p1, ml_p2, ml_p3, ml_p4, ml_p5;
	wire mr_p1, mr_p2, mr_p3, mr_p4, mr_p5;

	// Sensor inverters
	not
		u_n4(nS4, Sensors[4]),
		u_n3(nS3, Sensors[3]),
		u_n2(nS2, Sensors[2]),
		u_n1(nS1, Sensors[1]),
		u_n0(nS0, Sensors[0]);

	// AND-plane: ten product terms (five per motor).
	// ML = S3 S2 S1 + nS4 S2 nS0 + S3 S2 nS0 + nS4 nS3 S1 + nS4 nS3 nS2 S0
	// MR = nS4 S2 S1 + S3 S2 S1 + nS4 S2 nS0 + S3 nS1 nS0 + S4 nS2 nS1 nS0
	and
		u_ml1(ml_p1, Sensors[3], Sensors[2], Sensors[1]),
		u_ml2(ml_p2, nS4,        Sensors[2], nS0),
		u_ml3(ml_p3, Sensors[3], Sensors[2], nS0),
		u_ml4(ml_p4, nS4,        nS3,        Sensors[1]),
		u_ml5(ml_p5, nS4,        nS3,        nS2,         Sensors[0]),
		u_mr1(mr_p1, nS4,        Sensors[2], Sensors[1]),
		u_mr2(mr_p2, Sensors[3], Sensors[2], Sensors[1]),
		u_mr3(mr_p3, nS4,        Sensors[2], nS0),
		u_mr4(mr_p4, Sensors[3], nS1,        nS0),
		u_mr5(mr_p5, Sensors[4], nS2,        nS1,         nS0);

	// OR-plane and the two derived outputs.
	or
		u_or_ml(ML, ml_p1, ml_p2, ml_p3, ml_p4, ml_p5),
		u_or_mr(MR, mr_p1, mr_p2, mr_p3, mr_p4, mr_p5),
		u_or_im(InMotion, ML, MR);

	not u_n_err(Error, InMotion);

endmodule
