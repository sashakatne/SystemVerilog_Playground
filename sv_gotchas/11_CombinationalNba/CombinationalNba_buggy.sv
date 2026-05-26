// Gotcha #11: in a combinational `always` block, non-blocking assignment
// defers updates until the NBA region. Combined with an INCOMPLETE
// sensitivity list (here `always @(x)` does not include the intermediate
// variable `t`), the block never re-evaluates after t updates -- so the
// output `y` reflects the PREVIOUS x, not the current one. The output
// trails the input by one stimulus.
module CombinationalNba_buggy (
  input  [3:0] x,
  output reg [3:0] y
);
  reg [3:0] t;
  always @(x) begin
    t <= x + 4'd1;
    y <= t + 4'd1;       // reads OLD t -- y is stale by one stimulus
  end
endmodule
