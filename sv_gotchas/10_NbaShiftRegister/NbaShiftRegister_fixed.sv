// Fixed counterpart: nonblocking assignments. All right-hand sides are
// sampled in the Active region; the LHS updates happen later in the NBA
// region, so q2 sees the old q1 and out sees the old q2. The result is a
// proper 3-cycle delay line.
module NbaShiftRegister_fixed (
  input  clk,
  input  d,
  output reg out
);
  reg q1, q2;

  always @(posedge clk) begin
    q1  <= d;
    q2  <= q1;
    out <= q2;
  end
endmodule
