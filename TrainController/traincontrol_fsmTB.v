module top;

    // Inputs
    reg RESET, S5, S4, S3, S2, S1, CLK;
    // Outputs
    wire SW1, SW2, SW3, DA1, DA0, DB1, DB0;
    // Error counter
    integer errors = 0;

    parameter TRUE   = 1'b1;
    parameter FALSE  = 1'b0;
    parameter CLOCK_CYCLE  = 20;
    parameter CLOCK_WIDTH  = CLOCK_CYCLE/2;
    parameter IDLE_CLOCKS  = 2;

    // Instantiate the FSM module
    traincontroller_fsm DUT (RESET, S5, S4, S3, S2, S1, CLK, SW3, SW2, SW1, DA1, DA0, DB1, DB0);

    // Set up monitor
    initial begin
        $display("               Time RESET S5 S4 S3 S2 S1     SW3 SW2 SW1   DA1 DA0 DB1 DB0");
        $monitor($time, " %b     %b  %b  %b  %b  %b     %b   %b   %b      %b  %b   %b   %b", RESET, S5, S4, S3, S2, S1, SW3, SW2, SW1, DA1, DA0, DB1, DB0);
    end

    // Create free running clock
    initial begin
        CLK = FALSE;
        forever #CLOCK_WIDTH CLK = ~CLK;
    end

    // Generate Reset signal for two cycles
    initial begin
        RESET = TRUE;
        repeat (IDLE_CLOCKS) @(negedge CLK);
        RESET = FALSE;
    end

    // Generate stimulus after waiting for reset
    initial begin
        @(negedge RESET); // Wait for reset to complete
        #CLOCK_CYCLE;     // Wait for one clock cycle

        // Test state transitions based on the state transition diagram
        // AoutBout to Bincommon
        repeat (2) @(negedge CLK);
        S1 = FALSE; S2 = TRUE; S3 = FALSE; S4 = FALSE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("AoutBout to Bincommon", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1);

        // Bincommon to AoutBout
        repeat (2) @(negedge CLK);
        S1 = TRUE; S2 = FALSE; S3 = TRUE; S4 = FALSE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("Bincommon to AoutBout", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1);

        // AoutBout to Aincommon
        repeat (2) @(negedge CLK);
        S1 = TRUE; S2 = FALSE; S3 = FALSE; S4 = FALSE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("AoutBout to Aincommon", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1);

        // Aincommon to Bstop
        repeat (2) @(negedge CLK);
        S1 = FALSE; S2 = TRUE; S3 = FALSE; S4 = FALSE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("Aincommon to Bstop", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);

        // Bstop to Bincommon
        repeat (2) @(negedge CLK);
        S1 = FALSE; S2 = FALSE; S3 = FALSE; S4 = TRUE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("Bstop to Bincommon", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1);

        // Bincommon to Astop
        repeat (2) @(negedge CLK);
        S1 = TRUE; S2 = FALSE; S3 = FALSE; S4 = FALSE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("Bincommon to Astop", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1);

        // Astop to Aincommon
        repeat (2) @(negedge CLK);
        S1 = FALSE; S2 = FALSE; S3 = TRUE; S4 = FALSE; S5 = FALSE;
        repeat (2) @(posedge CLK);
        check_state("Astop to Aincommon", SW3, SW2, SW1, DA1, DA0, DB1, DB0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1);

        // Complete all the checks
        if (errors == 0) begin
            $display("All state transitions passed successfully.");
        end else begin
            $display("%d state transitions failed.", errors);
        end

        $finish;
    end

    // Task to check the state and increment error counter if mismatch occurs
    task check_state;
        input [31*8:0] state_name;
        input SW3, SW2, SW1, DA1, DA0, DB1, DB0;
        input expected_SW3, expected_SW2, expected_SW1;
        input expected_DA1, expected_DA0, expected_DB1, expected_DB0;
        begin
            if ((SW1 !== expected_SW1) || (SW2 !== expected_SW2) || (SW3 !== expected_SW3) ||
                (DA1 !== expected_DA1) || (DA0 !== expected_DA0) ||
                (DB1 !== expected_DB1) || (DB0 !== expected_DB0)) begin
                $display("Error in state %s at time %t", state_name, $time);
                $display("Got SW3=%b, SW2=%b, SW1=%b, DA1=%b, DA0=%b, DB1=%b, DB0=%b",
                    SW3, SW2, SW1, DA1, DA0, DB1, DB0);
                $display("Expected SW3=%b, SW2=%b, SW1=%b, DA1=%b, DA0=%b, DB1=%b, DB0=%b",
                    expected_SW3, expected_SW2, expected_SW1, expected_DA1, expected_DA0, expected_DB1, expected_DB0);
                errors = errors + 1;
            end
        end
    endtask

endmodule
