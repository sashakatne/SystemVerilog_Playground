// Gotcha #13 (fixed capture): a small positive delay (#1) moves the blocking
// assignment OUT OF the posedge's current time slot entirely. By the next
// nanosecond, the Active / Inactive / NBA / Postponed regions of the posedge
// time slot have all run, so the DUT's q holds its new value. This is the
// same effect `$strobe` and `$monitor` get from running in the Postponed
// region.
//
// (Note: `#0` would NOT work here -- `#0` schedules into the Inactive region,
//  which runs BEFORE NBA. A real-time-advancing delay is required.)
`timescale 1ns/100ps
module DisplayVsMonitor_fixed (
  input        clk,
  input  [7:0] q,
  output reg [7:0] captured
);
  always @(posedge clk) #1 captured = q;   // post-NBA via 1 ns advance
endmodule
