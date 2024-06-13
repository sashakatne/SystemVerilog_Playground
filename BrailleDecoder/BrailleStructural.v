module BrailleDigits(BCD,w,x,y,z);
input [3:0] BCD;
output w,x,y,z;

wire abar, bbar, cbar, dbar;
wire p0, p1 ,p2, p3, p4, p5, p6, p7;
 
not #10
  u1a(abar,BCD[3]),
  u1b(bbar,BCD[2]),
  u1c(cbar,BCD[1]),
  u1d(dbar,BCD[0]);
  
nand #10
  u2a(p0,abar,BCD[0]),
  u2b(p1,BCD[3],dbar),
  u4a(p2,abar,cbar,dbar),
  
  u2c(p3,BCD[1],BCD[0]),
  u2d(p4,BCD[2],BCD[1]),
  u3a(p5,BCD[3],BCD[0]),
  u3b(p6,BCD[2],BCD[0]),
  u3c(p7,bbar,dbar),
  
  u5a(w,bbar,cbar,p0,p1),
  u5b(x,p2,p3,p4,p5),
  u4b(y,p1,p2,p6),
  u4c(z,p4,p5,p7);
   
endmodule