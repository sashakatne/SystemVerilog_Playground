module top;

    parameter ADDRWIDTH = 8;
    parameter DATAWIDTH = 8;
    parameter CLOCK_PERIOD_NS = 10; // Clock period in nanoseconds, 100MHz

    reg clock;
    reg reset;
    reg ld_high, ld_low;
    reg [ADDRWIDTH-1:0] addr;
    reg [DATAWIDTH-1:0] din;
    reg write;
    reg zero;
    wire [DATAWIDTH-1:0] dout;
    wire busy;

    // Instantiate the mz module
    mz #(ADDRWIDTH, DATAWIDTH) DUT (
        .clock(clock),
        .reset(reset),
        .ld_high(ld_high),
        .ld_low(ld_low),
        .addr(addr),
        .din(din),
        .write(write),
        .zero(zero),
        .dout(dout),
        .busy(busy)
    );

    // Clock generation
    always #(CLOCK_PERIOD_NS / 2) clock = ~clock; // Generate clock with defined period

    // Helper task to wait for a number of clock cycles
    task wait_clock_cycles(input integer cycles);
        integer i;
        for (i = 0; i < cycles; i++) begin
            @(posedge clock);
        end
    endtask

    // Test sequence
    initial begin
        // Initialize inputs
        clock = 0;
        reset = 1;
        ld_high = 0;
        ld_low = 0;
        addr = 0;
        din = 0;
        write = 0;
        zero = 0;

        // Apply reset
        wait_clock_cycles(2);
        reset = 0;
        wait_clock_cycles(1);

        // Test Case 1: Write a value to a specific address
        @(negedge clock);
        addr = 8'hAA;
        din = 8'h55;
        write = 1;
        @(posedge clock);
        write = 0;
        wait_clock_cycles(1);
        if (dout !== 8'h55) $display("Test Case 1 Failed: Memory write error at address %h", addr);
        else $display("Test Case 1 Passed");

        // Test Case 2: Zero out a range of memory
        @(negedge clock);
        ld_high = 1; addr = 8'hFF; // Set high address for zeroing
        @(posedge clock);
        ld_high = 0;
        @(negedge clock);
        ld_low = 1; addr = 8'h00; // Set low address for zeroing
        @(posedge clock);
        ld_low = 0;
        @(negedge clock);
        zero = 1;
        @(posedge clock);
        zero = 0;
        wait_clock_cycles(100); // Wait for zeroing to complete
        @(negedge clock);
        addr = 8'h00;
        wait_clock_cycles(10);
        if (dout !== 8'h00) $display("Test Case 2 Failed: Memory zero error at address %h", addr);
        else $display("Test Case 2 Passed");

        // Test Case 3: Write and then zero out a range including the written address
        @(negedge clock);
        addr = 8'h55;
        din = 8'hAA;
        write = 1;
        @(posedge clock);
        write = 0;
        @(negedge clock);
        ld_high = 1; addr = 8'hFF;
        @(posedge clock);
        ld_high = 0;
        @(negedge clock);
        ld_low = 1; addr = 8'h00;
        @(posedge clock);
        ld_low = 0;
        @(negedge clock);
        zero = 1;
        @(posedge clock);
        zero = 0;
        wait_clock_cycles(100); // Wait for zeroing to complete
        @(negedge clock);
        addr = 8'h55;
        wait_clock_cycles(10);
        if (dout !== 8'h00) $display("Test Case 3 Failed: Memory zero error at address %h", addr);
        else $display("Test Case 3 Passed");

        // Test Case 4: Attempt to write while zeroing is in progress
        @(negedge clock);
        ld_high = 1; addr = 8'hFF;
        @(posedge clock);
        ld_high = 0;
        @(negedge clock);
        ld_low = 1; addr = 8'h00;
        @(posedge clock);
        ld_low = 0;
        @(negedge clock);
        zero = 1;
        @(posedge clock);
        addr = 8'h33;
        din = 8'h77;
        write = 1;
        wait_clock_cycles(1);
        write = 0;
        zero = 0;
        @(negedge clock);
        addr = 8'h33;
        wait_clock_cycles(10);
        if (dout === 8'h77) $display("Test Case 4 Failed: Write operation should not occur during zeroing");
        else $display("Test Case 4 Passed");

        // Test Case 5: Zero out a single address by setting high and low addresses the same
        @(negedge clock);
        ld_high = 1; addr = 8'hAA;
        @(posedge clock);
        ld_high = 0;
        @(negedge clock);
        ld_low = 1; addr = 8'hAA;
        @(posedge clock);
        ld_low = 0;
        @(negedge clock);
        zero = 1;
        @(posedge clock);
        zero = 0;
        wait_clock_cycles(100); // Wait for zeroing to complete
        @(negedge clock);
        addr = 8'hAA;
        wait_clock_cycles(10);
        if (dout !== 8'h00) $display("Test Case 5 Failed: Memory zero error at single address %h", addr);
        else $display("Test Case 5 Passed");

        // Test Case 6: Check busy flag behavior during zeroing
        @(negedge clock);
        ld_high = 1; addr = 8'hFF;
        @(posedge clock);
        ld_high = 0;
        @(negedge clock);
        ld_low = 1; addr = 8'h00;
        @(posedge clock);
        ld_low = 0;
        @(negedge clock);
        zero = 1;
        wait_clock_cycles(1);
        if (!busy) $display("Test Case 6 Failed: Busy flag not set during zeroing");
        @(posedge clock);
        zero = 0;
        wait_clock_cycles(100); // Wait for zeroing to complete
        if (busy) $display("Test Case 6 Failed: Busy flag not cleared after zeroing");
        else $display("Test Case 6 Passed");

        // Test Case 7: Normal mode operation after zero mode
        @(negedge clock);
        ld_high = 1; addr = 8'hFF;
        @(posedge clock);
        ld_high = 0;
        @(negedge clock);
        ld_low = 1; addr = 8'h00;
        @(posedge clock);
        ld_low = 0;
        @(negedge clock);
        zero = 1;
        @(posedge clock);
        zero = 0;
        wait_clock_cycles(100); // Wait for zeroing to complete
        @(negedge clock);
        addr = 8'hAA;
        din = 8'hBB;
        write = 1;
        @(posedge clock);
        write = 0;
        wait_clock_cycles(1);
        if (dout !== 8'hBB) $display("Test Case 7 Failed: Normal mode write error after zero mode");
        else $display("Test Case 7 Passed");

        // Finish the simulation
        wait_clock_cycles(10);
        $finish;
    end

endmodule
