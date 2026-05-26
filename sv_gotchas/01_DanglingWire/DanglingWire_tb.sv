// Side-by-side testbench. Drives all 8 input combinations through both DUTs,
// compares each to the reference majority-of-three function, and ends with the
// canonical pass line only if (a) the buggy version observably mismatched on
// at least one vector and (b) the fixed version matched on every vector.
module top;
  reg  A, B, C;
  wire Y_buggy, Y_fixed;
  reg  Y_expected;
  integer vec, n_buggy_caught, n_fixed_clean, errors;

  DanglingWire_buggy dut_buggy (.A(A), .B(B), .C(C), .Y(Y_buggy));
  DanglingWire_fixed dut_fixed (.A(A), .B(B), .C(C), .Y(Y_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  ABC   expected  buggy  fixed   verdict");
    for (vec = 0; vec < 8; vec = vec + 1) begin
      {A, B, C}  = vec[2:0];
      Y_expected = (A & B) | (B & C) | (A & C);
      #1;

      // !== so X on a buggy output is treated as a mismatch (rather than X)
      if (Y_buggy !== Y_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %b%b%b      %b        %b      %b    GOTCHA OBSERVED",
                 vec, A, B, C, Y_expected, Y_buggy, Y_fixed);
      end else begin
        $display(" %0d   %b%b%b      %b        %b      %b    (buggy matches)",
                 vec, A, B, C, Y_expected, Y_buggy, Y_fixed);
      end

      if (Y_fixed !== Y_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%b expected=%b",
                 vec, Y_fixed, Y_expected);
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
               n_buggy_caught, n_fixed_clean, 8);

    $finish;
  end
endmodule
