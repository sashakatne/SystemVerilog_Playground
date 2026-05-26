// Drives every possible 2-bit value of v. Buggy returns the default `0xFF`
// for v=2 and v=3 because the labels `10` and `11` are decimal ten and
// eleven, not the binary patterns the author meant.
module top;
  reg  [1:0]    v;
  wire [7:0]    code_buggy, code_fixed;
  reg  [7:0]    code_expected;
  integer       vec, n_buggy_caught, n_fixed_clean, errors;

  CaseUnsizedLiteral_buggy dut_buggy (.v(v), .code(code_buggy));
  CaseUnsizedLiteral_fixed dut_fixed (.v(v), .code(code_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  v   expected  buggy  fixed  verdict");
    for (vec = 0; vec < 4; vec = vec + 1) begin
      v = vec[1:0];
      case (vec)
        0: code_expected = 8'h10;
        1: code_expected = 8'h20;
        2: code_expected = 8'h30;
        3: code_expected = 8'h40;
      endcase
      #1;

      if (code_buggy !== code_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %b  %h        %h     %h     GOTCHA OBSERVED (unsized label never matched)",
                 vec, v, code_expected, code_buggy, code_fixed);
      end else begin
        $display(" %0d   %b  %h        %h     %h     (buggy matches -- label was decimal-equivalent)",
                 vec, v, code_expected, code_buggy, code_fixed);
      end

      if (code_fixed !== code_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%h want=%h",
                 vec, code_fixed, code_expected);
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
