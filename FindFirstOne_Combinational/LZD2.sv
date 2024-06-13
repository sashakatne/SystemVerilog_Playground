module LZD2(input logic [0:1] b, output logic v, output logic p);

    assign v = b[0] | b[1];
    assign p = ~b[0];
    
endmodule
