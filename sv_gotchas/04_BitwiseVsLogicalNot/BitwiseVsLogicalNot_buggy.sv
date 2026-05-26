// Gotcha #04: `if (~val)` uses bitwise NOT, which produces an N-bit vector,
// not a Boolean. In an `if`, the vector is treated as true iff ANY bit is
// non-zero -- equivalent to `val !== {N{1'b1}}`. So `if (~val)` is "fire
// unless val is all-ones", NOT "fire when val is zero".
//
// This module is a zero-detector. The buggy version uses `~val` where it
// should use `!val`, so it gives the WRONG ANSWER for two important values:
//   val = 0x00 (should report zero, reports non-zero)
//   val = 0xFF (should report non-zero, reports zero)
module BitwiseVsLogicalNot_buggy (
  input  [7:0] val,
  output       is_zero
);
  assign is_zero = (~val) ? 1'b0 : 1'b1;
endmodule
