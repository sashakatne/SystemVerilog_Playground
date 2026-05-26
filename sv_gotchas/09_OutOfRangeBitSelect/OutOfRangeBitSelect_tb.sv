// Drives four input vectors with different MSB values. Buggy always returns
// X (out-of-range bit-select), so the comparison against the true MSB fires
// on every vector.
module top;
  reg  [31:0] vec;
  wire        bit_msb_buggy, bit_msb_fixed;
  reg         bit_msb_expected;
  integer     i, n_buggy_caught, n_fixed_clean, errors;

  OutOfRangeBitSelect_buggy dut_buggy (.vec(vec), .bit_msb(bit_msb_buggy));
  OutOfRangeBitSelect_fixed dut_fixed (.vec(vec), .bit_msb(bit_msb_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  value       expected  buggy  fixed  verdict");
    for (i = 0; i < 4; i = i + 1) begin
      case (i)
        0: vec = 32'h80000000;
        1: vec = 32'h7FFFFFFF;
        2: vec = 32'h12345678;
        3: vec = 32'hFFFFFFFF;
      endcase
      bit_msb_expected = vec[31];
      #1;

      if (bit_msb_buggy !== bit_msb_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %h    %b         %b      %b     GOTCHA OBSERVED (out-of-range index -> X)",
                 i, vec, bit_msb_expected, bit_msb_buggy, bit_msb_fixed);
      end else begin
        $display(" %0d   %h    %b         %b      %b     (buggy matches)",
                 i, vec, bit_msb_expected, bit_msb_buggy, bit_msb_fixed);
      end

      if (bit_msb_fixed !== bit_msb_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%b want=%b",
                 i, bit_msb_fixed, bit_msb_expected);
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
