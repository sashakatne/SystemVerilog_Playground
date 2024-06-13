module top;

  import floatingpointpkg::*;
  float f;
  int maxint = ((1 << 31) -1);
  bit error_flag = '0;
  int maxtests = 200000;
  int num_errors = 0;
  int num_tests = 0;

  function bit testfptoint(float f);
    shortreal sr;
    real r; // Declare a variable of type real
    int n, t;
    if (!f.isnan() && !f.isinfinity()) begin
      sr = $bitstoshortreal(f.fbits);
      r = sr; // Explicit cast from shortreal to real
      if (sr > shortreal'(maxint))
        n = 32'h80000000;
      else if (sr < shortreal'(-maxint))
        n = 32'h80000000;
      else
        n = $rtoi(r);
      t = f.fptoint();
      if (n != 32'h80000000 && n !== t) begin
        $display("*** error ***\n fptoint f = %p, sr = %f, n = %d, t = %d", f.fbits, sr, n, t);
        return ('1); // Return error
      end
    end
    return ('0); // No error
  endfunction

  initial begin
    f = new();

    // Test the nodenorm_c constraint
    f.constraint_mode(0); // Disable all constraints
    f.nodenorm_c.constraint_mode(1); // Enable nodenorm_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (f.isdenorm()) begin
        $display("Error: Denormalized number generated when nodenorm_c is active: sign = %b, exponent = %b, fraction = %b", f.fbits.sign, f.fbits.exponent, f.fbits.fraction);
        num_errors++;
        error_flag = '1;
      end
    end

    // Test the alldenorm_c constraint
    f.constraint_mode(0); // Disable all constraints
    f.alldenorm_c.constraint_mode(1); // Enable alldenorm_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (!f.isdenorm()) begin
        $display("Error: Non-denormalized number generated when alldenorm_c is active: sign = %b, exponent = %b, fraction = %b", f.fbits.sign, f.fbits.exponent, f.fbits.fraction);
        num_errors++;
        error_flag = '1;
      end
    end

    // Test the nonan_c constraint
    f.constraint_mode(0); // Disable all constraints
    f.nonan_c.constraint_mode(1); // Enable nonan_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (f.isnan()) begin
        $display("Error: NaN generated when nonan_c is active: sign = %b, exponent = %b, fraction = %b", f.fbits.sign, f.fbits.exponent, f.fbits.fraction);
        num_errors++;
        error_flag = '1;
      end
    end

    // Test the noinf_c constraint
    f.constraint_mode(0); // Disable all constraints
    f.noinf_c.constraint_mode(1); // Enable noinf_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (f.isinfinity()) begin
        $display("Error: Infinity generated when noinf_c is active: sign = %b, exponent = %b, fraction = %b", f.fbits.sign, f.fbits.exponent, f.fbits.fraction);
        num_errors++;
        error_flag = '1;
      end
    end

    // Test the exprange_c constraint
    f.constraint_mode(0); // Disable all constraints
    f.set_exprange(-10, 20); // Set the range for exponent
    f.exprange_c.constraint_mode(1); // Enable exprange_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (!f.expinrange()) begin
        $display("Error: Exponent out of range when exprange_c is active: sign = %b, exponent = %b, fraction = %b", f.fbits.sign, f.fbits.exponent, f.fbits.fraction);
        num_errors++;
        error_flag = '1;
      end
      else begin
        if (testfptoint(f)) begin
          $display("Error: fptoint function failed.");
          num_errors++;
          error_flag = '1;
        end
      end
    end

    // Test the fptoint function for no denormalized numbers
    f.constraint_mode(1); // Enable all constraints
    f.alldenorm_c.constraint_mode(0); // Disable alldenorm_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (testfptoint(f)) begin
        $display("Error: fptoint function failed.");
        num_errors++;
        error_flag = '1;
      end
    end

    // Test the fptoint function for all denormalized numbers
    f.alldenorm_c.constraint_mode(1); // Enable alldenorm_c constraint
    f.nodenorm_c.constraint_mode(0); // Disable nodenorm_c constraint
    f.exprange_c.constraint_mode(0); // Disable exprange_c constraint
    repeat (maxtests) begin
      assert(f.randomize());
      num_tests++;
      if (testfptoint(f)) begin
        $display("Error: fptoint function failed.");
        num_errors++;
        error_flag = '1;
      end
    end

    // Display test results
    if(error_flag == '0)
      $display(" *** PASSED *** ");
    else
      $display(" *** FAILED *** ");
    $display("Percentage of tests passed out of a total %0d tests= %0.2f%%", num_tests, (num_tests - num_errors) * 100.0 / num_tests);

    $finish;
  end

endmodule
