// Fixed checker: triggers on every positive clock edge. Even if `actual`
// is stuck, the clock edge fires the always block, the !== comparison
// runs, and the mismatch is reported.
module VerifierSensitivityMiss_fixed (
  input        clk,
  input        actual,
  input        expected,
  output reg   error_flag,
  output reg [31:0] fire_count
);
  initial begin
    error_flag = 1'b0;
    fire_count = 32'd0;
  end

  always @(posedge clk) begin
    fire_count = fire_count + 1;
    if (actual !== expected) error_flag <= 1'b1;
  end
endmodule
