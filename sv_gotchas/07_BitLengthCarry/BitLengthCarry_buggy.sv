// Gotcha #07: Verilog determines expression width from context. Here `a + b`
// sits in a 16-bit assignment context, so the addition wraps modulo 2^16 and
// the carry-out is gone BEFORE the right-shift runs. The "average of two
// 16-bit numbers" silently wraps around for any inputs that sum past 2^16.
module BitLengthCarry_buggy (
  input  [15:0] a, b,
  output [15:0] avg
);
  assign avg = (a + b) >> 1;
endmodule
