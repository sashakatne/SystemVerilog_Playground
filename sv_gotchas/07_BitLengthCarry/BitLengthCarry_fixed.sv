// Fixed counterpart: adding the unsized integer literal `0` (which is 32-bit
// in Verilog) widens the entire RHS expression to 32 bits, so the addition
// runs in 32-bit context, the carry survives, and the right-shift sees the
// full 17-bit sum. Truncation back to 16 bits happens only at the final
// assignment, which is fine because the shift has already dropped the LSB.
module BitLengthCarry_fixed (
  input  [15:0] a, b,
  output [15:0] avg
);
  assign avg = (a + b + 0) >> 1;
endmodule
