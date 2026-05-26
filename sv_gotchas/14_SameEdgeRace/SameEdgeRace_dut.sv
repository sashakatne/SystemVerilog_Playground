// Shared DUT: a positive-edge flip-flop. The interesting timing happens in
// the driver modules, not here.
module SameEdgeRace_dut (
  input        clk,
  input        d,
  output reg   q
);
  always @(posedge clk) q <= d;
endmodule
