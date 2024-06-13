module top;

    // Parameters of the ALU
    localparam DATA_WIDTH = 16;
    localparam RESULT_WIDTH = 32;

    // Testbench signals
    logic clk;
    logic rst;
    logic start_op;
    logic [2:0] op_sel;
    logic [DATA_WIDTH-1:0] A, B;
    logic [RESULT_WIDTH-1:0] result;
    logic end_op;
    bit error_flag = '0;

    // Instantiate the ALU
    cascaded_ece593_alu #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .start_op(start_op),
        .op_sel(op_sel),
        .A1(A),
        .B1(B),
        .result(result),
        .end_op(end_op)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate a clock with 10ns period (100MHz)
    end

    // Test sequence control
    initial begin
        // Initialize signals
        rst <= '1;
        repeat (2) @(negedge clk);
        rst <= '0;
        start_op <= '0;

        $display("************ Starting ALU test ************");
        // $display("************ Test for all operations with 21 and 42 ************");

        // Test with numbers 21 and 42
        for (int i = 0; i < 8; i++) begin
            perform_operation(i, 42, 21);
        end

        // $display("************ Test for all operations with 0 and 0 ************");
        // Test with numbers 0 and 0
        for (int i = 0; i < 8; i++) begin
            perform_operation(i, 0, 0);
        end

        // $display("************ Test for all operations with maximum positive numbers ************");
        // Test with maximum positive numbers
        for (int i = 0; i < 8; i++) begin
            perform_operation(i, {DATA_WIDTH{1'b1}}, {DATA_WIDTH{1'b1}});
        end

        // $display("************ Test for all operations with maximum negative numbers ************");
        // Test with maximum negative numbers
        for (int i = 0; i < 8; i++) begin
            perform_operation(i, -32768, -32768);
        end

        // $display("************ Test for all operations with 100 random numbers ************");
        // Test with random numbers
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 10000; j++) begin
                perform_operation(i, $random % {DATA_WIDTH{1'b1}}, $random % {DATA_WIDTH{1'b1}});
            end
        end

        // Check if any errors were detected
        if (error_flag) begin
            $display("*** FAILED ***");
        end else begin
            $display("*** PASSED ***");
        end

        // Finish the simulation
        @(posedge clk);
        $finish;
    end

    task perform_operation(input logic [2:0] op, input logic [DATA_WIDTH-1:0] opA, input logic [DATA_WIDTH-1:0] opB);
        int cycle_count;
        begin
            @(negedge clk);
            A <= opA;
            B <= opB;
            op_sel <= op;
            start_op <= '1;
            cycle_count = 0;

            // $display("Stimulus at time: %0tns, OpSel: %0b, A: %0d, B: %0d", $time, op, opA, opB);
            
            fork
            wait (end_op); // Wait for the operation to complete
            while (!end_op) begin
                @(posedge clk);
                cycle_count++;
                // Timeout if cycle count exceeds 10
                if (cycle_count > 10) begin
                    error_flag = '1;
                    $display("Error: timeout while waiting for operation=%0b to complete for A=%0d and B=%0d", op, opA, opB);
                    $finish;
                end
            end
            join_any;

            start_op <= '0;
            @(negedge clk);

            check_result(op, opA, opB, cycle_count);
            // Wait for random number of cycles between tests
            repeat($random % 10) @(posedge clk);
        end
    endtask

    task check_result(input logic [2:0] op, input logic [DATA_WIDTH-1:0] opA, input logic [DATA_WIDTH-1:0] opB, input int cycle_count);
        logic [RESULT_WIDTH-1:0] expected;
        string op_name;

        begin
            // Compute the expected result
            case (op)
                3'b000: begin
                    op_name = "MUL"; 
                    expected = opA * opB;
                end
                3'b001: begin
                    op_name = "ADD";
                    expected = opA + opB;
                end
                3'b010: begin
                    op_name = "SUB";
                    expected = opA - opB;
                end
                3'b011: begin
                    op_name = "ADDINCR";
                    expected = opA + opB + 1;
                end
                3'b100: begin
                    op_name = "OR";
                    expected = opA | opB;
                end
                3'b101: begin
                    op_name = "AND";
                    expected = opA & opB;
                end
                3'b110: begin
                    op_name = "XOR";
                    expected = opA ^ opB;
                end
                3'b111: begin
                    op_name = "NOT";
                    expected = {~opA, ~opB};
                end
            endcase

            // Display the operation, expected result, actual result, and end_op signal for each stimulus
            // $display("Operation: %0s", op_name);
            // $display("Time: %0tns, A: %0d, B: %0d, Expected: %0d, Result: %0d, cycles to complete: %0d", $time, opA, opB, expected, result, cycle_count);

            // Check the result
            if (result !== expected) begin
                error_flag = '1;
                $display("Test Failed at time %0t: Operation %0s with A = %0d and B = %0d resulted in %0d, expected %0d.", $time, op_name, opA, opB, result, expected);
            end

            // Check if the cycle count matches the expected duration for the operation
            if ((op == 3'b000 && cycle_count != 3) || (op != 3'b000 && cycle_count != 1)) begin
                error_flag = '1;
                $display("Test Failed: Operation %0s with A = %0d and B = %0d took %0d cycles, expected %0d cycles to complete.", op_name, opA, opB, cycle_count, (op == 3'b000) ? 3 : 1);
            end

            // Ensure that end_op has been asserted
            if (!end_op) begin
                error_flag = '1;
                $display("Test Failed: end_op was not asserted as expected after operation %0b.", op);
            end
        end
    endtask

endmodule
