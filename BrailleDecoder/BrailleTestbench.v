
/*
 *
 *  Known Good Device for Braille self checking testbench
 *
 */
 
module KGD(BCD,w,x,y,z);
input [3:0] BCD;
output reg w,x,y,z;

always @(BCD)
case (BCD)
	0: {w,x,y,z} = 4'b0111;
	1: {w,x,y,z} = 4'b1000;
	2: {w,x,y,z} = 4'b1001;
	3: {w,x,y,z} = 4'b1100;
	4: {w,x,y,z} = 4'b1110;
	5: {w,x,y,z} = 4'b1010;
	6: {w,x,y,z} = 4'b1101;
	7: {w,x,y,z} = 4'b1111;
	8: {w,x,y,z} = 4'b1011;
	9: {w,x,y,z} = 4'b0101;
	default:  {w,x,y,z} = 4'bxxxx;
endcase
endmodule



module top();
localparam DELAY = 1000;
reg [3:0] BCD;
wire w0, x0, y0, z0;	// known good outputs
wire w, x, y, z;		// DUT outputs
reg Errors;
integer i;

KGD KGD0(BCD, w0, x0, y0, z0);
BrailleDigits DUT(BCD, w, x, y, z);

initial
begin
// $dumpfile("dump.vcd"); $dumpvars;
Errors = 0;
  for (i = 0; i <= 9; i = i+1)
  begin
  BCD = i;
  #(DELAY)
  if ({w,x,y,z} !== {w0,x0,y0,z0})
      begin
      $display("*** Error: BCD = %d, expecting {w,x,y,z} = %b, got %b",BCD,{w0,x0,y0,z0},{w,x,y,z});
      Errors = 1;
      end
  end
  
if (Errors == 0)
  $display("No errors -- passed testbench");
else
  $display("Failed testbench");
$finish();
end
endmodule
