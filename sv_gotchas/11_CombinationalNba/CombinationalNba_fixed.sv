// Fixed counterpart: blocking assignment in a combinational always block.
// Each statement sees the just-written value of the previous one, so `y`
// reflects the current `x` in one delta.
module CombinationalNba_fixed (
  input  [3:0] x,
  output reg [3:0] y
);
  reg [3:0] t;
  always @* begin
    t = x + 4'd1;
    y = t + 4'd1;        // sees NEW t
  end
endmodule
