module LZDn(v0, v1, p0, p1, v, p);

    parameter n = 32;
    input v0, v1;
    input [0:$clog2(n)-2] p0, p1;
    output v;
    output [0:$clog2(n)-1] p;

    // Calculate the width of the priority output based on parameter n
    localparam int priority_width = $clog2(n) - 1;
    // Valid output is the OR of the two valid inputs
    assign v = v0 | v1;
    // Priority calculation
    assign p[0] = ~v0;

    // Use a for-loop to assign the rest of the priority bits based on v0, p0, and p1
    genvar i;
    generate
        for (i = 0; i < priority_width; i = i + 1) begin : priority_assignment
            assign p[i+1] = (v0 & p0[i]) | (~v0 & p1[i]);
        end
    endgenerate

endmodule

