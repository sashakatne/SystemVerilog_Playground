// Testbench for N-bit Sequential Multiplier

module top;

    parameter N = 8;
    reg [N-1:0] multiplicand, multiplier;
    wire [2*N-1:0] product;
    reg [2*N-1:0] expected_product;
    reg start;
    wire ready;
    bit Error;
    reg reset;
    reg clock = '1;

    // Instantiate the SequentialMultiplier module
    SequentialMultiplier #(N) DUT (clock, reset, multiplicand, multiplier, product, ready, start);

    // Function to calculate the expected product
    function [2*N-1:0] calc_expected_product;
        input [N-1:0] a, b;
        begin
            calc_expected_product = a * b;
        end
    endfunction

    task WaitForReady;
    begin
        fork
            wait(ready);
            repeat(N) @(negedge clock); // Multiply takes N cycles
        join_any

        if (!ready) begin
            $display("Error: timeout while waiting for ready, multiplicand = %d, multiplier = %d", multiplicand, multiplier);
            Error = '1;
        end
    end
    endtask

    // Task to check results
    task CheckResults;
    begin
        expected_product = calc_expected_product(multiplicand, multiplier);
        WaitForReady;
        if (product !== expected_product) begin
            $display("Error: %d * %d != %d Expected %d)", multiplicand, multiplier, product, expected_product);
            Error = '1;
        end
        start = 0;
    end
    endtask

    // Clock generation
    initial begin

        `ifdef DEBUG
            $dumpfile("dump.vcd"); $dumpvars;
            $display("               time         clock reset start ready              multiplicand                    product   multiplier");
            $monitor($time,"           %b   %b    %b     %b    %b %d %d",clock, reset, start, ready, multiplicand, product, multiplier);
        `endif

        forever #50 clock = ~clock;

    end

    // Test sequence
    initial begin
        
        Error = '0;
        @(negedge clock);
        reset = '1;
        repeat (2) @(negedge clock);
        reset = '0;

        multiplicand = $random;
        multiplier = $random;
        WaitForReady;

        for (int i = 0; i < (1 << N); i++) begin
            
            start = 1;

            `ifdef DEBUG
                $display("Starting test %d: %d * %d", i, multiplicand, multiplier);
            `endif

            @(negedge clock);
            if (ready) begin
                $display("Error: ready still asserted one cycle after start asserted");
                Error = '1;
            end
            if ($random() % 2)
            start = 0;

            CheckResults;

            @(negedge clock);
            multiplicand = $random;
            multiplier = $random;

            repeat ($random() % 5) @(negedge clock); // Should be able to stay in initial state without start

        end

        if (Error)
            $display("\n\n *** FAILED *** \n\n");
        else
            $display("\n\n *** PASSED *** \n\n");

        // Terminate the simulation
        $finish;
    end

endmodule
