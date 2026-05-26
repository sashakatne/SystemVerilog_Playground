// Gotcha #16 (fixed): intra-assignment NBA delay inside an always block gives
// TRANSPORT semantics. Each input change schedules its own NBA update; none
// of them cancel each other, so every pulse -- including ones much shorter
// than the delay -- appears on the output 10 ns later, preserving its width.
`timescale 1ns/100ps
module InertialDelaySwallow_fixed (
  input  a,
  input  b,
  output reg y
);
  initial y = 1'b0;
  always @(a or b) y <= #10 (a & b);
endmodule
