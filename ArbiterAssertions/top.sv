module top;

    localparam n=8;
    // Clock and reset signals
    logic clock;
    logic reset;

    // Request and grant vectors
    logic [0:n-1] r;
    logic [0:n-1] g;

    Arbiter DUT(clock, reset, r, g);
    bind Arbiter ArbiterAssertions arbiter_assertions_inst(clock, reset, r, g);

    initial begin
        clock = '0;
        forever #5 clock = ~clock;  // 100 MHz clock
    end

    initial begin
        $timeformat(-9, 0, "ns", 6);
        $display(" time reset request grant\n");
        $monitor("%t %2b %8b %8b", $time, reset, r, g);
    end

    // Stimulus for the arbiter
    initial begin

        reset = '1;
        repeat (2) @(posedge clock);
        reset = '0;
        @(posedge clock);
        // Test 0: Request or grant vector should never have invalid bits
        @(posedge clock); r = 'z;         // Invalid request
        @(posedge clock); r = 'x;         // Invalid request
        @(posedge clock); r = '0;  // No requests
        
        // Test 1: Single request and grant
        @(posedge clock); r = 8'b00000001;  // Agent 7 requests
        @(posedge clock); r = '0;  // No requests

        // Test 1a: Multiple requests and check priority encoding
        @(posedge clock); r = 8'b00001000;  // Agents 4 and 7 request
        @(posedge clock); r = '0;  // No requests

        // Test 2: Multiple requests and check priority encoding
        @(posedge clock); r = 8'b11000000;  // Agents 0 and 1 request
        @(posedge clock); r = '0;  // No requests

        // Test 2a: Multiple requests and check priority encoding
        @(posedge clock); r = 8'b00001001;  // Agents 4 and 7 request
        @(posedge clock); r = '0;  // No requests

        // Test 3: Grant is produced in one cycle
        @(posedge clock); r = 8'b00100000;  // Agent 2 requests
        @(posedge clock); r = '0;  // No requests

        // Test 4: Never more than one simultaneous grant
        @(posedge clock); r = 8'b10101010;  // Multiple requests
        @(posedge clock); r = '0;  // No requests

        // Test 5: Grant is never given to an agent that didn’t request it
        @(posedge clock); r = 8'b00010000;  // Agent 3 requests
        @(posedge clock); r = '0;  // No requests

        // Test 6: Grant is never revoked if the agent continues to request
        @(posedge clock); r = 8'b00001000;  // Agent 4 requests
        @(posedge clock); r = 8'b00001000;  // Agent 4 continues to request
        @(posedge clock); r = 8'b00001000;  // Agent 4 continues to request again
        @(posedge clock); r = '0;  // No requests

        // Test 7: An agent which has received a grant should not continue to request it for more than 256 total cycles
        @(posedge clock); r = 8'b00000010; // Agent 6 requests
        repeat (257) @(posedge clock);     // Continue request for 257 cycles
        @(posedge clock); r = '0;  // No requests

        // Test 7a: An agent which has received a grant should not continue to request it for more than 256 total cycles
        @(posedge clock); r = 8'b00000100; // Agent 5 requests
        repeat (257) @(posedge clock);     // Continue request for 257 cycles
        @(posedge clock); r = '0;  // No requests

        // Test 7b: An agent which has received a grant should not continue to request it for more than 256 total cycles
        @(posedge clock); r = 8'b01000000;  // Agent 1 requests
        repeat (128) @(posedge clock);      // Continue request for 128 cycles
        @(posedge clock); r = '0;  // No requests
        @(posedge clock); r = 8'b01000000;  // Agent 1 requests again
        repeat (172) @(posedge clock);      // Continue request for 172 cycles
        @(posedge clock); r = '0;  // No requests

        // Test 7c: An agent which has received a grant should not continue to request it for more than 256 total cycles
        @(posedge clock); r = 8'b11000000;  // Agent 1 requests
        repeat (128) @(posedge clock);      // Continue request for 128 cycles
        @(posedge clock); r = '0;  // No requests

        // Reset module
        reset = '1;
        repeat (2) @(posedge clock);
        reset = '0;
        @(posedge clock);

        // Exhaustive testing
        @(posedge clock); r = 'x;
        for (int i = 0; i < (2**n); i = i + 1)
            begin
                repeat ($random() % 3) @(posedge clock);
                r = i;
                @(posedge clock);
            end
        // Allow some time for the last request to be processed and assertions to be checked
        repeat (10) @(posedge clock);
        
        // End the simulation
        $finish;
    end
endmodule
