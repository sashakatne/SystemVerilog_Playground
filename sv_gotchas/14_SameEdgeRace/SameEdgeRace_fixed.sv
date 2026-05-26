// Fixed driver: drives stimulus on the OPPOSITE clock edge (negedge). By
// the next posedge, `d` is stable on the wire and the DUT samples cleanly.
module SameEdgeRace_fixed (
  input      clk,
  input      start,   // here repurposed as the per-cycle stim value
  output reg d
);
  initial d = 1'b0;
  always @(negedge clk) begin
    d <= start;
  end
endmodule
