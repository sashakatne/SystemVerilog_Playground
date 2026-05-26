// Gotcha #16 (buggy): `assign #10 y = a & b;` is INERTIAL. If a&b changes
// faster than 10 ns, the pending output transition is cancelled and replaced
// by the new one. Any input pulse strictly shorter than 10 ns is therefore
// SILENTLY SWALLOWED -- y never transitions for it. A designer who wrote
// this thinking they were modeling pure wire delay has accidentally added a
// glitch filter.
`timescale 1ns/100ps
module InertialDelaySwallow_buggy (
  input  a,
  input  b,
  output y
);
  assign #10 y = a & b;
endmodule
