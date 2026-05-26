// Drives four vectors through both checkers, the last two of which contain
// X / Z bits on the `actual` input. The fixed checker correctly raises
// mismatch=1; the buggy one returns X, which a downstream `if (mismatch)`
// would treat as false, hiding the bug.
module top;
  reg  [7:0] actual, expected;
  wire       mismatch_buggy, mismatch_fixed;
  reg        mismatch_expected;
  integer    vec, n_buggy_caught, n_fixed_clean, errors;

  EqualityX_buggy dut_buggy (.actual(actual), .expected(expected), .mismatch(mismatch_buggy));
  EqualityX_fixed dut_fixed (.actual(actual), .expected(expected), .mismatch(mismatch_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  actual      expected   want_mismatch  buggy  fixed   verdict");
    for (vec = 0; vec < 4; vec = vec + 1) begin
      case (vec)
        0: begin actual = 8'h3C; expected = 8'h3C; mismatch_expected = 1'b0; end
        1: begin actual = 8'h3C; expected = 8'h7F; mismatch_expected = 1'b1; end
        2: begin actual = 8'bxxxxxxxx; expected = 8'h3C; mismatch_expected = 1'b1; end
        3: begin actual = 8'bzzzzzzzz; expected = 8'h3C; mismatch_expected = 1'b1; end
      endcase
      #1;

      if (mismatch_buggy !== mismatch_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %b  %b   %b              %b      %b      GOTCHA OBSERVED  (buggy returns X, downstream `if` treats as false)",
                 vec, actual, expected, mismatch_expected, mismatch_buggy, mismatch_fixed);
      end else begin
        $display(" %0d   %b  %b   %b              %b      %b      (buggy matches)",
                 vec, actual, expected, mismatch_expected, mismatch_buggy, mismatch_fixed);
      end

      if (mismatch_fixed !== mismatch_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%b want=%b",
                 vec, mismatch_fixed, mismatch_expected);
      end else begin
        n_fixed_clean = n_fixed_clean + 1;
      end
    end

    if (n_buggy_caught == 0)
      $display("*** Error: gotcha never triggered -- demo is silently passing");
    else if (errors != 0)
      $display("*** Error: %0d fix-version mismatches", errors);
    else
      $display("No errors -- passed testbench  (gotcha caught %0d times, fix clean %0d/%0d)",
               n_buggy_caught, n_fixed_clean, 4);

    $finish;
  end
endmodule
