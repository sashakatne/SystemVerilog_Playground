// Gotcha #03: ?: with X (or Z) on the predicate evaluates BOTH arms and
// bit-blends them per the 4-state OR table (0|1 = x, x|x = x). If the two
// arms hold different bit values, every disagreeing bit position turns into
// X on the output, even when neither arm itself contains any X.
module ConditionalX_buggy (
  input        sel,
  input  [7:0] a,
  input  [7:0] b,
  output [7:0] result
);
  assign result = sel ? a : b;
endmodule
