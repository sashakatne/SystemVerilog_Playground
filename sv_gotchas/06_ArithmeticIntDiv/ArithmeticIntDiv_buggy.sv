// Gotcha #06: in Verilog/SystemVerilog, an integer literal divided by another
// integer literal is INTEGER division, not real division. `(1/4)` is 0, NOT
// 0.25. So writing `base * (1/4)` to mean "a quarter of base" gives 0 for
// every input.
//
// Variants of the same trap: `9.0 ** (1/2)` is `9.0 ** 0 == 1.0` (not 3.0);
// `-13 % 4` is -1 (modulo follows the dividend's sign).
module ArithmeticIntDiv_buggy (
  input  [7:0]  base,
  output [15:0] quarter
);
  assign quarter = base * (1/4);   // (1/4) folds to 0 -> result always 0
endmodule
