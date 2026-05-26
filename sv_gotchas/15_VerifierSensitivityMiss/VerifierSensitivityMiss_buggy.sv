// Gotcha #15 (buggy checker): the checker only fires when `actual` changes.
// If the DUT bug holds `actual` stuck at X (or Z), the @(actual) event
// never triggers, and the checker never reports the mismatch. The bug
// passes silently.
module VerifierSensitivityMiss_buggy (
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

  always @(actual) begin
    fire_count = fire_count + 1;
    if (actual !== expected) error_flag <= 1'b1;
  end
endmodule
