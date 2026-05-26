// Drives all 8 input combinations of {A,B,C}. For each vector, samples the
// buggy and fixed call counters before and after, compares the deltas, and
// reports a GOTCHA OBSERVED whenever the buggy version did extra work the
// fixed version skipped. The Boolean result must still agree across the two.
module top;
  reg     A, B, C;
  wire    result_buggy, result_fixed;
  wire [31:0] count_buggy, count_fixed;
  reg     result_expected;
  integer vec, n_buggy_caught, n_fixed_clean, errors;
  integer buggy_before, fixed_before, buggy_delta, fixed_delta;
  integer expected_fixed_delta;

  ShortCircuitSideEffect_buggy dut_buggy (.A(A), .B(B), .C(C),
                                          .result(result_buggy),
                                          .call_count(count_buggy));
  ShortCircuitSideEffect_fixed dut_fixed (.A(A), .B(B), .C(C),
                                          .result(result_fixed),
                                          .call_count(count_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    // settle: drive {A,B,C}=0 once and account for any initial-fire counts
    A = 0; B = 0; C = 0;
    #1;

    $display("vec  ABC  expected  buggy_result  fixed_result  buggy_dcalls  fixed_dcalls  verdict");
    for (vec = 0; vec < 8; vec = vec + 1) begin
      buggy_before = count_buggy;
      fixed_before = count_fixed;
      {A, B, C}    = vec[2:0];
      #1;

      result_expected      = (A & (B | C));            // same Boolean either way
      expected_fixed_delta = (A === 1'b1 && B === 1'b0) ? 1 : 0;  // logical && short-circuit
      buggy_delta          = count_buggy - buggy_before;
      fixed_delta          = count_fixed - fixed_before;

      // result correctness check (both DUTs)
      if (result_buggy !== result_expected) begin
        errors = errors + 1;
        $display("     *** BUGGY result wrong on vec=%0d  buggy=%b want=%b",
                 vec, result_buggy, result_expected);
      end
      if (result_fixed !== result_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%b want=%b",
                 vec, result_fixed, result_expected);
      end

      // gotcha: extra side effects in the buggy version
      if (buggy_delta > fixed_delta) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %b%b%b      %b         %b             %b             %0d              %0d           GOTCHA OBSERVED (%0d extra call(s))",
                 vec, A, B, C, result_expected, result_buggy, result_fixed,
                 buggy_delta, fixed_delta, buggy_delta - fixed_delta);
      end else begin
        $display(" %0d   %b%b%b      %b         %b             %b             %0d              %0d           (counts match)",
                 vec, A, B, C, result_expected, result_buggy, result_fixed,
                 buggy_delta, fixed_delta);
      end

      // fix-clean accounting: fixed must take the short-circuit when it should
      if (fixed_delta == expected_fixed_delta)
        n_fixed_clean = n_fixed_clean + 1;
      else begin
        errors = errors + 1;
        $display("     *** FIX FAILED: fixed_delta=%0d expected_delta=%0d on vec=%0d",
                 fixed_delta, expected_fixed_delta, vec);
      end
    end

    $display("final: buggy.call_count=%0d  fixed.call_count=%0d", count_buggy, count_fixed);

    if (n_buggy_caught == 0)
      $display("*** Error: gotcha never triggered -- demo is silently passing");
    else if (errors != 0)
      $display("*** Error: %0d fix-version mismatches", errors);
    else
      $display("No errors -- passed testbench  (gotcha caught %0d times, fix clean %0d/%0d)",
               n_buggy_caught, n_fixed_clean, 8);

    $finish;
  end
endmodule
