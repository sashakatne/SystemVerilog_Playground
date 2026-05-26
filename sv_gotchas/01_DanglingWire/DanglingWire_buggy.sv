// Gotcha #01: silent dangling wire.
// Verilog does not require nets to be declared. A typo in a net name silently
// creates a fresh 1-bit wire that no driver connects to, so it stays at X
// forever and any gate that consumes it produces X.
//
// This module computes the majority-of-three function (Y = A&B | B&C | A&C)
// from three AND gates feeding one OR gate. The OR connection has a typo:
// the intermediate net `bc` is referenced as `BC` (uppercase). Verilog accepts
// it as an implicit 1-bit net, never driven, so the OR gate sees an X on that
// input. `vlog -lint` catches this.
module DanglingWire_buggy (
  input  A, B, C,
  output Y
);
  wire ab, bc, ac;

  and a1 (ab, A, B);
  and a2 (bc, B, C);  // bc is driven here ...
  and a3 (ac, A, C);

  or  o1 (Y, ab, BC, ac);  // ... but BC (uppercase) is a different, dangling net
endmodule
