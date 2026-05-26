// Fixed counterpart: case-equality (===) lets us detect an X / Z selector
// explicitly and pick a defined default (here: `b`) instead of letting the
// X-blend poison the output. The select is treated as a real-valued 0/1/x/z
// without bit-blending.
module ConditionalX_fixed (
  input        sel,
  input  [7:0] a,
  input  [7:0] b,
  output [7:0] result
);
  assign result = (sel === 1'b1) ? a
                : (sel === 1'b0) ? b
                : b;   // sel is X or Z -- fall back to b deterministically
endmodule
