module top;

    // Testbench signals
    reg [0:31] b;
    wire v_ffo32, v_ffop;
    wire [0:4] p_ffo32;
    wire [0:4] p_ffop;
    integer i, j;
    reg Errors;
    localparam DELAY = 1;

    // Instantiate the Unit Under Test (UUT)
    FFO32 DUT (b, v_ffo32, p_ffo32);

    // Instantiate the Known Good Device (KGD)
    FFOp #(32) kgd (b, v_ffop, p_ffop);

    // Test procedure
    initial begin

        Errors = 0;
        // All zeros. The priority output is undefined, hence only the valid output is compared
        b = {32{1'b0}};
        #(DELAY);
        if (v_ffo32 !== v_ffop) begin
            $display("*** Error: b = %b, v = %b, got v = %b", b, v_ffop, v_ffo32);
            Errors = Errors + 1;
        end

        // All dont-cares
        b = {32{1'bx}};
        #(DELAY);
        if (v_ffo32 !== v_ffop || p_ffo32 !== p_ffop) begin
            $display("*** Error: b = %b, v = %b, p = %b, got v = %b, p = %b", b, v_ffop, p_ffop, v_ffo32, p_ffo32);
            Errors = Errors + 1;
        end

        // Initialize b with 'X' to represent don't-care conditions
        b = {32{1'bx}};
        // Test only the significant bit positions by setting one bit at a time
        for (i = 0; i < 32; i = i + 1) begin
            // Set the bits leading up to the '1' to zero
            for (j = 0; j < i; j = j + 1) begin
                b[j] = 1'b0;
            end
            b[i] = 1'b1; // Set only one bit at position i
            // The rest of the bits after 'i' are already 'X' (don't care)
            #(DELAY);
            if (v_ffo32 !== v_ffop || p_ffo32 !== p_ffop) begin
                $display("*** Error: b = %b, v = %b, p = %b, got v = %b, p = %b", b, v_ffop, p_ffop, v_ffo32, p_ffo32);
                Errors = Errors + 1;
            end
        end

        // Report test result
        if (Errors == 0) begin
            $display("No errors -- passed testbench");
        end
        else begin
            $display("Failed testbench");
        end
        // Finish the simulation
        $finish;
    end

endmodule

