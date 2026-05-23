// Self-checking testbench for the parameterized BarrelShifter.
//
// Strategy:
//   1. Sweep every legal ShiftAmount (0..N-1) with a handful of distinctive
//      input patterns under both ShiftIn=0 and ShiftIn=1.
//   2. Hit edge ShiftAmounts (0, 1, N/2, N-1) explicitly with extra patterns
//      so the boundary stages are exercised.
//   3. Follow with a batch of random vectors for breadth.
// Each comparison prints a PASS/FAIL line; the run ends with the canonical
// "No errors -- passed testbench" line on success.
module top;

    parameter int N = 32;
    localparam int SBITS = $clog2(N);

    logic [N-1:0]       In;
    logic [SBITS-1:0]   ShiftAmount;
    logic               ShiftIn;
    logic [N-1:0]       Out;

    BarrelShifter #(.N(N)) DUT (
        .In          (In),
        .ShiftAmount (ShiftAmount),
        .ShiftIn     (ShiftIn),
        .Out         (Out)
    );

    int errors = 0;
    int checks = 0;

    // Reference model: behavioural left shift with ShiftIn replicated into the
    // vacated LSBs. Truncated to N bits to match the DUT.
    function automatic logic [N-1:0] ref_shift(
        input logic [N-1:0]     in_val,
        input logic [SBITS-1:0] shamt,
        input logic             shift_in
    );
        logic [N-1:0] shifted;
        logic [N-1:0] fill;
        shifted = in_val << shamt;
        fill    = shift_in ? ((({{(N-1){1'b0}}, 1'b1}) << shamt) - 1'b1) : '0;
        return shifted | fill;
    endfunction

    task automatic check(
        input logic [N-1:0]     in_val,
        input logic [SBITS-1:0] shamt,
        input logic             shift_in
    );
        logic [N-1:0] expected;
        In          = in_val;
        ShiftAmount = shamt;
        ShiftIn     = shift_in;
        #1;
        expected = ref_shift(in_val, shamt, shift_in);
        checks++;
        if (Out !== expected) begin
            $display("FAIL [%0d]: In=%h ShiftAmount=%0d ShiftIn=%b => Out=%h expected=%h",
                     checks, in_val, shamt, shift_in, Out, expected);
            errors++;
        end else begin
            $display("PASS [%0d]: In=%h ShiftAmount=%0d ShiftIn=%b => Out=%h",
                     checks, in_val, shamt, shift_in, Out);
        end
    endtask

    // Pattern set covering corner bit distributions.
    logic [N-1:0] patterns [0:6];

    initial begin
        patterns[0] = '0;
        patterns[1] = '1;
        patterns[2] = {N{1'b1}} ^ (N'(1));                // all ones except LSB
        patterns[3] = N'('hDEAD_BEEF);
        patterns[4] = N'('hA5A5_A5A5);
        patterns[5] = N'(1);                              // single LSB set
        patterns[6] = N'(1) << (N-1);                     // single MSB set

        // 1. Sweep every shift amount against every pattern, both ShiftIn values.
        for (int p = 0; p < $size(patterns); p++) begin
            for (int sa = 0; sa < N; sa++) begin
                check(patterns[p], sa[SBITS-1:0], 1'b0);
                check(patterns[p], sa[SBITS-1:0], 1'b1);
            end
        end

        // 2. Random vectors for additional breadth.
        for (int i = 0; i < 200; i++) begin
            logic [N-1:0] rin;
            rin = {$urandom(), $urandom()};               // 64 bits, truncated by N
            check(rin, $urandom_range(0, N-1), $urandom_range(0, 1));
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
