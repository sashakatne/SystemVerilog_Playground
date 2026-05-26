// Fixed counterpart: logical && and || short-circuit. `A && (B || f(C))`
// only calls f when A is true AND B is false; otherwise f is skipped, and
// `call_count` stays put for that vector.
module ShortCircuitSideEffect_fixed (
  input            A, B, C,
  output reg       result,
  output reg [31:0] call_count
);
  initial call_count = 32'd0;

  function automatic logic f(input bit x);
    call_count = call_count + 1;
    f = x;
  endfunction

  always @(A or B or C) begin
    result = A && (B || f(C));  // logical -- f(C) only when A=1 && B=0
  end
endmodule
