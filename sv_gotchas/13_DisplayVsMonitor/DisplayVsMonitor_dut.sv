// Shared DUT for demo #13: a one-byte register that updates via NBA on each
// posedge. The interesting timing happens in the checker modules, not here.
`timescale 1ns/100ps
module DisplayVsMonitor_dut (
  input        clk,
  input  [7:0] d,
  output reg [7:0] q
);
  always @(posedge clk) q <= d;
endmodule
