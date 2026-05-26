// Fixed counterpart: same majority-of-three structure, but every net name
// matches its declaration. `vlog -lint` is clean.
module DanglingWire_fixed (
  input  A, B, C,
  output Y
);
  wire ab, bc, ac;

  and a1 (ab, A, B);
  and a2 (bc, B, C);
  and a3 (ac, A, C);

  or  o1 (Y, ab, bc, ac);
endmodule
