// Gotcha #08: in a `case` statement, the case labels are expressions, not
// patterns -- and an unsized integer literal like `10` is DECIMAL ten
// (32-bit), not binary 2'b10. So in `case (v) 00:..; 01:..; 10:..; 11:..`
// only `00` (decimal 0) and `01` (decimal 1) ever match a 2-bit `v`; `10`
// (decimal 10) and `11` (decimal 11) never match. The decoder silently
// returns the `default` branch on half its inputs.
module CaseUnsizedLiteral_buggy (
  input  [1:0]     v,
  output reg [7:0] code
);
  always @* begin
    case (v)
      00: code = 8'h10;   // decimal 0  -- matches v=2'b00
      01: code = 8'h20;   // decimal 1  -- matches v=2'b01
      10: code = 8'h30;   // decimal 10 -- NEVER matches a 2-bit v
      11: code = 8'h40;   // decimal 11 -- NEVER matches a 2-bit v
      default: code = 8'hFF;
    endcase
  end
endmodule
