// Gotcha #10: blocking assignments in sequential always blocks collapse a
// multi-stage shift register into a single flip-flop, because each blocking
// statement executes immediately and the following one reads the just-written
// value rather than the value held in the upstream register.
module NbaShiftRegister_buggy (
  input  clk,
  input  d,
  output reg out
);
  reg q1, q2;

  always @(posedge clk) begin
    q1  = d;    // q1 takes the new d immediately
    q2  = q1;   // q2 takes the new q1 (= d) immediately
    out = q2;   // out takes the new q2 (= d) -- one-cycle delay, not three
  end
endmodule
