// Gotcha #14 (buggy driver): drives stimulus on the same posedge the DUT
// samples on, using a blocking assignment. In Questa's NBA scheduling the
// DUT's @(posedge clk) NBA-RHS reads `d` in the Active region BEFORE this
// driver's blocking write fires -- so the DUT silently samples the OLD `d`
// and the captured output lags every change by one cycle. The simulator
// happens to be self-consistent across cycles, but the result is one full
// cycle behind what the testbench author intended.
module SameEdgeRace_buggy (
  input      clk,
  input      start,   // here repurposed as the per-cycle stim value
  output reg d
);
  initial d = 1'b0;
  always @(posedge clk) begin
    d = start;       // blocking, on the DUT's sampling edge
  end
endmodule
