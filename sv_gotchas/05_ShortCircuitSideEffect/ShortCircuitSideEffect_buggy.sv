// Gotcha #05: bitwise & and | DO NOT short-circuit. The full right-hand
// side is always evaluated, including any function calls with side effects.
// `A & (B | f(C))` will call `f` on every evaluation, even when A is 0 and
// the value of `f(C)` cannot possibly affect the result.
//
// The function `f` here writes a module-level call counter. The TB compares
// the buggy and fixed counters per-vector to make the gotcha countable.
module ShortCircuitSideEffect_buggy (
  input            A, B, C,
  output reg       result,
  output reg [31:0] call_count
);
  initial call_count = 32'd0;

  function automatic logic f(input bit x);
    call_count = call_count + 1;
    f = x;
  endfunction

  // explicit sensitivity to avoid `call_count` self-triggering the block
  always @(A or B or C) begin
    result = A & (B | f(C));   // bitwise -- f(C) always called
  end
endmodule
