// Fixed counterpart: a single always block that explicitly encodes the
// priority. `counter` has one writer, the priority is in the source.
module MultipleDrivers_fixed (
  input            clk,
  input            sig_a,
  input            sig_b,
  output reg [7:0] counter
);
  initial counter = 8'd0;

  always @(posedge clk) begin
    if      (sig_a) counter <= 8'h0A;   // sig_a wins when both asserted
    else if (sig_b) counter <= 8'h0B;
  end
endmodule
