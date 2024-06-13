
module FFOp(b, v, p);

    parameter w = 4;
    input [0:w-1] b;
    output reg v;
    output reg [0:$clog2(w)-1] p;

    integer i;
    always @(b) begin
        v = |b; // Reduction OR operation to determine if any bit is set
        if (v) begin
            // If valid, search for the first '1'
            for (i = 0; i < w; i = i + 1) begin
                if (b[i]) begin
                    p = i;
                    break; // Exit the loop once the first '1' is found
                end
            end
        end
        // If b is zero, 'p' remains undefined as per the specification
    end
    
endmodule
