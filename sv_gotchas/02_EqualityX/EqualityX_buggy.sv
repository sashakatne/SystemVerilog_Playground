// Gotcha #02: == / != return X (not 0 or 1) when either operand has an X or Z
// bit. A testbench that uses `if (actual != expected) ErrorFound = 1;` will
// silently SKIP the error report when `actual` is undriven, because the `if`
// condition evaluates to X (treated as false).
//
// This module is a one-bit mismatch detector. The buggy version uses `!=`,
// so it returns X (not 1) when `actual` contains an X.
module EqualityX_buggy (
  input  [7:0] actual,
  input  [7:0] expected,
  output       mismatch
);
  assign mismatch = (actual != expected);
endmodule
