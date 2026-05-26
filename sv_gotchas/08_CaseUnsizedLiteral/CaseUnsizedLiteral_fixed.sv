// Fixed counterpart: sized binary literals make the labels mean what the
// author intended.
module CaseUnsizedLiteral_fixed (
  input  [1:0]     v,
  output reg [7:0] code
);
  always @* begin
    case (v)
      2'b00: code = 8'h10;
      2'b01: code = 8'h20;
      2'b10: code = 8'h30;
      2'b11: code = 8'h40;
      default: code = 8'hFF;
    endcase
  end
endmodule
