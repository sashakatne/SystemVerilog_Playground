module top;

    parameter N = 8; // Width of the counter
    parameter CLK_PERIOD = 10; // Clock period in nanoseconds

    // Testbench signals
    reg clk;
    reg reset;
    reg load;
    reg [N-1:0] value;
    reg decr;
    wire timeup;

    // Instantiate the countdown timer
    countdowntimer #(.N(N)) DUT (
        .clk(clk),
        .reset(reset),
        .load(load),
        .value(value),
        .decr(decr),
        .timeup(timeup)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test failure flag
    integer errors = 0;

    // Initial block for test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        load = 0;
        value = 0;
        decr = 0;

        // Reset the timer
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;

        // Load a value and decrement
        @(negedge clk) load = 1; value = 8'h05;
        @(negedge clk) load = 0; decr = 1;

        // Check if the timer counts down correctly
        repeat (5) @(negedge clk);
            if (!timeup) begin
                $display("Error: timeup not asserted when counter should be zero.");
                errors = errors + 1;
            end

        // Check if timeup is asserted correctly
        @(negedge clk);
        if (!timeup) begin
            $display("Error: timeup not asserted when counter should be zero.");
            errors = errors + 1;
        end

        // Check if the timer stays at zero
        repeat (2) @(negedge clk);
        if (!timeup && decr) begin
            $display("Error: Counter did not stay at zero or timeup was deasserted while decrementing.");
            errors = errors + 1;
        end

        // Load a new value to see if timeup is de-asserted
        @(negedge clk) load = 1; value = 8'h08;
        @(negedge clk) load = 0;
        if (timeup) begin
            $display("Error: timeup not de-asserted after reload.");
            errors = errors + 1;
        end

        repeat (3) @(negedge clk) decr = 1;
        repeat (3) @(negedge clk) decr = 0;
        @(negedge clk) decr = 1;

        // Check if the timer counts down correctly and stops counting when decr is de-asserted
        repeat (5) @(negedge clk);
        if (!timeup) begin
            $display("Error: timeup not asserted when counter should be zero.");
            errors = errors + 1;
        end

        // Check for test results
        if (errors == 0) begin
            $display("All tests passed successfully.");
        end else begin
            $display("%d test(s) failed.", errors);
        end

        // Finish the simulation
        $finish;
    end

endmodule
