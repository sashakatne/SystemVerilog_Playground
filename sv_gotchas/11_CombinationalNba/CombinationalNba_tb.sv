// Drives a sequence of x values. After each settle, samples both DUTs and
// compares to the reference (y = x + 2). The buggy DUT trails the input by
// one stimulus: after applying x=k, its y is still equal to (x_prev + 2),
// not (x_curr + 2).
module top;
  reg  [3:0] x;
  wire [3:0] y_buggy, y_fixed;
  reg  [3:0] y_expected;
  integer    vec, n_buggy_caught, n_fixed_clean, errors;

  CombinationalNba_buggy dut_buggy (.x(x), .y(y_buggy));
  CombinationalNba_fixed dut_fixed (.x(x), .y(y_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    // initial settle (also "primes" the buggy DUT's internal `t`)
    x = 4'd0;
    #1;

    $display("vec  x  expected  buggy  fixed  verdict");
    for (vec = 0; vec < 5; vec = vec + 1) begin
      case (vec)
        0: x = 4'd1;
        1: x = 4'd5;
        2: x = 4'd9;
        3: x = 4'd3;
        4: x = 4'd14;
      endcase
      y_expected = x + 4'd2;
      #1;

      if (y_buggy !== y_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %0d   %0d         %0d      %0d     GOTCHA OBSERVED (NBA + stale t)",
                 vec, x, y_expected, y_buggy, y_fixed);
      end else begin
        $display(" %0d   %0d   %0d         %0d      %0d     (buggy matches by coincidence)",
                 vec, x, y_expected, y_buggy, y_fixed);
      end

      if (y_fixed !== y_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%0d want=%0d",
                 vec, y_fixed, y_expected);
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
