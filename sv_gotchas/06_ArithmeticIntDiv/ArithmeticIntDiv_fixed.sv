// Fixed counterpart: do the integer-arithmetic division directly. If a real
// quotient were actually needed, the operands would have to be cast to real
// (`real'(1) / real'(4)`).
module ArithmeticIntDiv_fixed (
  input  [7:0]  base,
  output [15:0] quarter
);
  assign quarter = base / 4;
endmodule
