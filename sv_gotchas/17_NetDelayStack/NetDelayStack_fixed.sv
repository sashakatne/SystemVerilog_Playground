// Fixed counterpart: the designer wanted a single 7 ns logic delay, so they
// write the single continuous assignment they actually intended.
`timescale 1ns/100ps
module NetDelayStack_fixed (
  input  Y,
  output D
);
  assign #7 D = Y;
endmodule
