// Shared DUT for demo #15: an output reg the design "forgot" to drive.
// With no driver, `actual` stays at the default X value for every
// simulated nanosecond. Crucially, there is never a transition on it, so
// any checker that uses `always @(actual)` will never fire.
module VerifierSensitivityMiss_dut (
  input        clk,
  output reg   actual
);
  // intentionally absent: no always block drives `actual`. Stays at X.
endmodule
