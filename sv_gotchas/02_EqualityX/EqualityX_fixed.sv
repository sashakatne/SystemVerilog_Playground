// Fixed counterpart: `!==` (case-inequality) compares bit-by-bit including
// X and Z, and always returns a real 0 or 1. So an X on `actual` produces
// mismatch=1, exactly as a self-checking testbench would want.
module EqualityX_fixed (
  input  [7:0] actual,
  input  [7:0] expected,
  output       mismatch
);
  assign mismatch = (actual !== expected);
endmodule
