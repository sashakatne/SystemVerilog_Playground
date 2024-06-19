module top;

    // Testbench signals
    reg CK;
    wire CK1;
    wire CK1_b;
    wire CK2;
    wire CK2_b;
    bit error_flag = '0;
    bit ck1_toggled = '0;
    bit ck2_toggled = '0;
    reg ck1_prev;
    reg ck2_prev;
    bit start_checking = '0;

    // Instantiate the top module
    novckgen DUT (
        .CK(CK),
        .CK1(CK1),
        .CK1_b(CK1_b),
        .CK2(CK2),
        .CK2_b(CK2_b)
    );

    // Clock generation
    initial begin
        CK = 0;
        forever #5 CK = ~CK; // 10ns period clock
    end

    // Self-checking logic
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        // Monitor the signals
        $monitor("Time: %0t | CK: %b | CK1: %b | CK1_b: %b | CK2: %b | CK2_b: %b", 
                 $time, CK, CK1, CK1_b, CK2, CK2_b);
    end

    // Start checking after a brief initial delay
    initial begin
        repeat (2) @(posedge CK); // Waits for 5 clock cycles
        start_checking = '1;
        ck1_prev = CK1;
        ck2_prev = CK2;
    end

    // Continuous monitoring for overlap and complementary checks
    always @(posedge CK or negedge CK) begin
        if (start_checking) begin
            // Check if CK1 toggles
            if (ck1_prev != CK1) begin
                ck1_toggled = '1;
            end else if (!ck1_toggled) begin
                $display("Error: CK1 did not toggle at time %0t", $time);
                error_flag = '1;
            end
            ck1_prev = CK1;
        
            // Check if CK2 toggles
            if (ck2_prev != CK2) begin
                ck2_toggled = '1;
            end else if (!ck2_toggled) begin
                $display("Error: CK2 did not toggle at time %0t", $time);
                error_flag = '1;
            end
            ck2_prev = CK2;
        end
    end

    always @(CK1 or CK2 or CK1_b or CK2_b) begin
        if (start_checking) begin
            // Check for overlap between CK1 and CK2
            if (CK1 & CK2) begin
                $display("Error: Overlap detected between CK1 and CK2 at time %0t", $time);
                error_flag = '1;
            end

            // Check for correct generation of CK1 and CK2
            if (CK1 !== ~CK1_b) begin
                $display("Error: CK1 and CK1_b are not complementary at time %0t", $time);
                error_flag = '1;
            end

            if (CK2 !== ~CK2_b) begin
                $display("Error: CK2 and CK2_b are not complementary at time %0t", $time);
                error_flag = '1;
            end
        end
    end

    // End the simulation after a specific time
    initial begin
        #1000;
        if (error_flag) begin
            $display("*** FAILED ***");
        end
        else begin
            $display("*** PASSED ***");
        end
        $stop;
    end

endmodule
