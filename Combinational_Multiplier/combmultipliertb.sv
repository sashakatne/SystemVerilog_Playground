module top;

    parameter N = 4;
    localparam DELAY = 10;
    reg [N-1:0] multiplicand;
    reg [N-1:0] multiplier;
    wire [2*N-1:0] product;
    reg [2*N-1:0] expected_product;
    integer i, j;
    bit error_flag;

    // Instantiate the multiplier module
    NxN_multiplier #(N) DUT (multiplicand, multiplier, product);

    // Testbench logic
    initial begin
        error_flag = '0;
        // Test all possible combinations of multiplicand and multiplier
        for (i = 0; i < (1 << N); i++) begin
            for (j = 0; j < (1 << N); j++) begin
                multiplicand = i;
                multiplier = j;
                expected_product = multiplicand * multiplier;
                #DELAY;
                // Check if the product matches the expected value
                if (product !== expected_product) begin
                    $display("Error: multiplicand = %b, multiplier = %b, expected = %b, got = %b",
                             multiplicand, multiplier, expected_product, product);
                    error_flag = '1;
                end
            end
        end
        if (error_flag)
            $display("\n\n *** FAILED *** \n\n");
        else
            $display("\n\n *** PASSED *** \n\n"); 
        $finish;
    end

endmodule
