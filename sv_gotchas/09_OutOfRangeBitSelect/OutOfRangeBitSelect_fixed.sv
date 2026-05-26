// Fixed counterpart: index the actual MSB, vec[31].
module OutOfRangeBitSelect_fixed (
  input  [31:0] vec,
  output        bit_msb
);
  assign bit_msb = vec[31];
endmodule
