module top;

    parameter N = 32;
    reg clock;
    reg reset;
    reg start;
    reg [N-1:0] b;
    wire parity;
    wire ready;
    bit error_flag = '0;
    
    // Instantiate the paritygen module
    paritygen #(.N(N)) DUT (clock, reset, start, b, parity, ready);
    
    initial begin
        // Clock generation
        forever #5 clock = ~clock; // 100MHz clock
    end

    // Test stimulus
    initial begin
        // Initialize signals
        clock = 0;
        reset = 0;
        start = 0;
        b = 0;

        // Reset the device
        @(negedge clock) reset = 1;
        @(negedge clock) reset = 0;

        // Apply parameterized test vectors
        repeat (10) begin // Repeat tests for different random values
            @(negedge clock);
            start = 1;
            b = $random; // Random test vector
            @(negedge clock);
            start = 0;
            wait (ready);
            check_parity(parity, expected_parity(b)); // Check the result
        end

        // Finish the simulation
        @(negedge clock);
        $finish;
    end

    // Function to calculate expected parity
    function logic expected_parity(input logic [N-1:0] vector);
        logic result;
        begin
            result = ^vector; // XOR all bits to calculate parity
            return ~result;
        end
    endfunction

    // Task to check the parity result
    task check_parity;
        input logic actual_parity;
        input logic expected_parity;
        begin
            @(negedge clock); // Check at the negative edge of the clock
            if (actual_parity !== expected_parity) begin
                $display("Test failed: Expected parity = %b, Actual parity = %b", expected_parity, actual_parity);
                error_flag = 1;
            end else begin
                // $display("Test passed: Expected parity = %b, Actual parity = %b", expected_parity, actual_parity);
                error_flag = 0;
            end
        end
    endtask

    initial begin
        if (error_flag)
            $display("\n\n *** FAILED *** \n\n");
        else
            $display("\n\n *** PASSED *** \n\n"); 
    end

endmodule
