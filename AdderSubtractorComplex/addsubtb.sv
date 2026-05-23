module AddSub8BitReference #(parameter int N = 8) (result, x, y, ccn, ccz, ccv, ccc, sub);
    input  logic [N-1:0] x, y;
    output logic [N-1:0] result;
    output logic ccn, ccz, ccv, ccc;
    input  logic sub;

    logic [N-1:0] y_effective;
    logic [N:0] extended_result;

    always_comb begin
        y_effective = sub ? ~y : y;
        extended_result = {1'b0, x} + {1'b0, y_effective} + sub;
        result = extended_result[N-1:0];
        ccn = result[N-1];
        ccz = (result == '0);
        ccv = (x[N-1] == y_effective[N-1]) && (result[N-1] != x[N-1]);
        ccc = extended_result[N];
    end

endmodule


module top;

    parameter int N = 8;
    localparam int VALUES = 1 << N;

    logic [N-1:0] x;
    logic [N-1:0] y;
    logic [N-1:0] result;
    logic [N-1:0] expected_result;
    logic ccn;
    logic ccz;
    logic ccv;
    logic ccc;
    logic expected_ccn;
    logic expected_ccz;
    logic expected_ccv;
    logic expected_ccc;
    logic sub;

    int checks = 0;
    int errors = 0;

    AddSub8Bit #(.N(N)) DUT (
        .result (result),
        .x      (x),
        .y      (y),
        .ccn    (ccn),
        .ccz    (ccz),
        .ccv    (ccv),
        .ccc    (ccc),
        .sub    (sub)
    );

    AddSub8BitReference #(.N(N)) KGD (
        .result (expected_result),
        .x      (x),
        .y      (y),
        .ccn    (expected_ccn),
        .ccz    (expected_ccz),
        .ccv    (expected_ccv),
        .ccc    (expected_ccc),
        .sub    (sub)
    );

    task automatic check(
        input logic [N-1:0] x_val,
        input logic [N-1:0] y_val,
        input logic sub_val
    );
        x = x_val;
        y = y_val;
        sub = sub_val;
        #1;

        checks++;
        if ((result !== expected_result) ||
            (ccn !== expected_ccn) ||
            (ccz !== expected_ccz) ||
            (ccv !== expected_ccv) ||
            (ccc !== expected_ccc)) begin
            $display("FAIL [%0d]: x=%h y=%h sub=%b => result=%h ccn=%b ccz=%b ccv=%b ccc=%b expected result=%h ccn=%b ccz=%b ccv=%b ccc=%b",
                     checks, x_val, y_val, sub_val, result, ccn, ccz, ccv, ccc,
                     expected_result, expected_ccn, expected_ccz, expected_ccv, expected_ccc);
            errors++;
        end else begin
            $display("PASS [%0d]: x=%h y=%h sub=%b => result=%h ccn=%b ccz=%b ccv=%b ccc=%b",
                     checks, x_val, y_val, sub_val, result, ccn, ccz, ccv, ccc);
        end
    endtask

    initial begin
        for (int sub_i = 0; sub_i < 2; sub_i++) begin
            for (int x_i = 0; x_i < VALUES; x_i++) begin
                for (int y_i = 0; y_i < VALUES; y_i++) begin
                    check(x_i[N-1:0], y_i[N-1:0], sub_i[0]);
                end
            end
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
