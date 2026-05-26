// Gotcha #13 (buggy capture): reads the DUT's q in the Active region of a
// posedge by using a blocking assignment in another always block at the same
// edge. Because the DUT's NBA on q has not yet executed, `captured` gets the
// OLD value of q. This is the same problem `$display` exhibits when used to
// trace sequential signals at the clock edge.
`timescale 1ns/100ps
module DisplayVsMonitor_buggy (
  input        clk,
  input  [7:0] q,
  output reg [7:0] captured
);
  always @(posedge clk) captured = q;   // active region read -- sees pre-NBA q
endmodule
