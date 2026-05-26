// Fixed counterpart: logical NOT (`!val`) reduces the vector to a single bit
// and inverts it, giving a proper Boolean is-zero check.
module BitwiseVsLogicalNot_fixed (
  input  [7:0] val,
  output       is_zero
);
  assign is_zero = (!val) ? 1'b1 : 1'b0;
endmodule
