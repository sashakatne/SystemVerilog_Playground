// Gotcha #12: two separate `always @(posedge clk)` blocks both writing the
// same register. The IEEE spec leaves the result unspecified when both
// blocks fire on the same edge with conflicting writes -- in practice the
// simulator picks one (Questa: source order; the last NBA to land wins). A
// designer who expected `sig_a` to take priority gets the OPPOSITE answer.
module MultipleDrivers_buggy (
  input            clk,
  input            sig_a,
  input            sig_b,
  output reg [7:0] counter
);
  initial counter = 8'd0;

  // Block 1 (author's intent: sig_a has priority)
  always @(posedge clk) begin
    if (sig_a) counter <= 8'h0A;
  end

  // Block 2 (added later by someone else, unaware of the existing writer)
  always @(posedge clk) begin
    if (sig_b) counter <= 8'h0B;
  end
endmodule
