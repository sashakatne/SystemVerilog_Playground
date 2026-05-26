// Drives a handful of values that span the "should produce nonzero" range.
// Buggy outputs 0 for every input because `(1/4)` is 0. Fixed outputs base/4.
module top;
  reg  [7:0]  base;
  wire [15:0] quarter_buggy, quarter_fixed;
  reg  [15:0] quarter_expected;
  integer     vec, n_buggy_caught, n_fixed_clean, errors;

  ArithmeticIntDiv_buggy dut_buggy (.base(base), .quarter(quarter_buggy));
  ArithmeticIntDiv_fixed dut_fixed (.base(base), .quarter(quarter_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  base  expected(=base/4)  buggy  fixed  verdict");
    for (vec = 0; vec < 5; vec = vec + 1) begin
      case (vec)
        0: base = 8'd0;
        1: base = 8'd4;
        2: base = 8'd16;
        3: base = 8'd100;
        4: base = 8'd200;
      endcase
      quarter_expected = base / 4;
      #1;

      if (quarter_buggy !== quarter_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %0d    %0d                 %0d     %0d     GOTCHA OBSERVED ((1/4) folded to 0)",
                 vec, base, quarter_expected, quarter_buggy, quarter_fixed);
      end else begin
        $display(" %0d   %0d    %0d                 %0d     %0d     (buggy matches -- both zero)",
                 vec, base, quarter_expected, quarter_buggy, quarter_fixed);
      end

      if (quarter_fixed !== quarter_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%0d want=%0d",
                 vec, quarter_fixed, quarter_expected);
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
               n_buggy_caught, n_fixed_clean, 5);

    $finish;
  end
endmodule
