module top;

    logic a;
    logic b;
    logic cin;
    logic sum;
    logic cout;

    int checks = 0;
    int errors = 0;

    FullAdder DUT (
        .sum  (sum),
        .cout (cout),
        .a    (a),
        .b    (b),
        .cin  (cin)
    );

    task automatic check(
        input logic a_val,
        input logic b_val,
        input logic cin_val
    );
        logic [1:0] expected;
        a = a_val;
        b = b_val;
        cin = cin_val;
        #1;

        expected = {1'b0, a_val} + {1'b0, b_val} + {1'b0, cin_val};
        checks++;
        if ({cout, sum} !== expected) begin
            $display("FAIL [%0d]: a=%b b=%b cin=%b => cout=%b sum=%b expected=%b",
                     checks, a_val, b_val, cin_val, cout, sum, expected);
            errors++;
        end else begin
            $display("PASS [%0d]: a=%b b=%b cin=%b => cout=%b sum=%b",
                     checks, a_val, b_val, cin_val, cout, sum);
        end
    endtask

    initial begin
        for (int i = 0; i < 8; i++) begin
            check(i[2], i[1], i[0]);
        end

        $display("");
        $display("Ran %0d checks, %0d errors", checks, errors);
        if (errors == 0)
            $display("No errors -- passed testbench");
        else
            $display("FAILED -- %0d errors", errors);
        $finish;
    end

endmodule
