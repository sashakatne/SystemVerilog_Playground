// Drives four interesting values: 0x00 (zero), 0xFF (all ones), 0xAA, 0x01.
// The buggy module reports the wrong answer for 0x00 (false negative -- it
// SAYS the value is non-zero) and 0xFF (false positive -- it SAYS the value
// is zero). Both errors are spectacular because they invert the answer.
module top;
  reg  [7:0] val;
  wire       is_zero_buggy, is_zero_fixed;
  reg        is_zero_expected;
  integer    vec, n_buggy_caught, n_fixed_clean, errors;

  BitwiseVsLogicalNot_buggy dut_buggy (.val(val), .is_zero(is_zero_buggy));
  BitwiseVsLogicalNot_fixed dut_fixed (.val(val), .is_zero(is_zero_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  val   expected  buggy  fixed  verdict");
    for (vec = 0; vec < 4; vec = vec + 1) begin
      case (vec)
        0: begin val = 8'h00; is_zero_expected = 1'b1; end
        1: begin val = 8'hFF; is_zero_expected = 1'b0; end
        2: begin val = 8'hAA; is_zero_expected = 1'b0; end
        3: begin val = 8'h01; is_zero_expected = 1'b0; end
      endcase
      #1;

      if (is_zero_buggy !== is_zero_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %h    %b         %b      %b     GOTCHA OBSERVED",
                 vec, val, is_zero_expected, is_zero_buggy, is_zero_fixed);
      end else begin
        $display(" %0d   %h    %b         %b      %b     (buggy matches)",
                 vec, val, is_zero_expected, is_zero_buggy, is_zero_fixed);
      end

      if (is_zero_fixed !== is_zero_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%b want=%b",
                 vec, is_zero_fixed, is_zero_expected);
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
