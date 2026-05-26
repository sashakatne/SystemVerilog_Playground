// Drives sel = 0, 1, X with arms that mutually disagree (a=AA, b=55), then
// once more with sel = X but arms that agree (a=b=33). The third vector is
// where the gotcha bites: a buggy ?: with X predicate poisons every bit
// because every bit position has 1-on-one-side and 0-on-the-other.
module top;
  reg        sel;
  reg  [7:0] a, b;
  wire [7:0] result_buggy, result_fixed;
  reg  [7:0] result_expected;
  integer    vec, n_buggy_caught, n_fixed_clean, errors;

  ConditionalX_buggy dut_buggy (.sel(sel), .a(a), .b(b), .result(result_buggy));
  ConditionalX_fixed dut_fixed (.sel(sel), .a(a), .b(b), .result(result_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  sel  a   b   expected  buggy  fixed  verdict");
    for (vec = 0; vec < 4; vec = vec + 1) begin
      case (vec)
        0: begin sel = 1'b0; a = 8'hAA; b = 8'h55; result_expected = 8'h55; end
        1: begin sel = 1'b1; a = 8'hAA; b = 8'h55; result_expected = 8'hAA; end
        2: begin sel = 1'bx; a = 8'hAA; b = 8'h55; result_expected = 8'h55; end // fix falls back to b
        3: begin sel = 1'bx; a = 8'h33; b = 8'h33; result_expected = 8'h33; end // arms agree; no X-blend
      endcase
      #1;

      if (result_buggy !== result_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %b    %h  %h  %h        %h     %h     GOTCHA OBSERVED",
                 vec, sel, a, b, result_expected, result_buggy, result_fixed);
      end else begin
        $display(" %0d   %b    %h  %h  %h        %h     %h     (buggy matches)",
                 vec, sel, a, b, result_expected, result_buggy, result_fixed);
      end

      if (result_fixed !== result_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%h want=%h",
                 vec, result_fixed, result_expected);
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
