// Gotcha #09: a bit-select index that falls outside the declared range of a
// vector returns X silently. No compile error, no warning by default. So an
// off-by-one (here `vec[32]` on a `[31:0]` register) corrupts whatever logic
// consumes the MSB output.
module OutOfRangeBitSelect_buggy (
  input  [31:0] vec,
  output        bit_msb
);
  assign bit_msb = vec[32];   // off-by-one: 32 is past the [31:0] range
endmodule
