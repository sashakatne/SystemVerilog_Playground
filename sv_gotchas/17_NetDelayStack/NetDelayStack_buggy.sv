// Gotcha #17: net delay STACKS with continuous-assignment delay. A designer
// who writes `wire #3 D_int; assign #7 D_int = Y;` may think they have a
// 7 ns logic delay and a separate 3 ns piece of wire annotation -- but the
// actual propagation from Y to a consumer of D_int is 7 + 3 = 10 ns, and
// each stage applies its own inertial filter.
//
// Here we model the stacking explicitly with two cascaded assigns through
// an intermediate wire, which is the equivalent (and unambiguous) form.
`timescale 1ns/100ps
module NetDelayStack_buggy (
  input  Y,
  output D
);
  wire D_int;
  assign #3 D_int = Y;
  assign #7 D     = D_int;
endmodule
