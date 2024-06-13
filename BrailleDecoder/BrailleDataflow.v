module BrailleDigits(BCD,w,x,y,z);
input [3:0] BCD;
output w,x,y,z;

assign w = ~BCD[3] & BCD[0] | BCD[1] | BCD[2] | BCD[3] & ~BCD[0];
assign x = ~BCD[3] & ~BCD[1] & ~BCD[0] | BCD[1] & BCD[0] | BCD[3] & BCD[0] | BCD[2] & BCD[1];
assign y =  BCD[3] & ~BCD[0] | BCD[2] & BCD[0] | ~BCD[3] & ~BCD[1] & ~BCD[0];
assign z =  BCD[3] | BCD[2] & BCD[1] | ~BCD[2] & ~BCD[0];

endmodule