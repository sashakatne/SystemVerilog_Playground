module top;

  // Import the floating point package
  import floatingpointpkg::*;

  // Declare variables
  float f, f1, f2, f3;
  shortreal sr;
  bit error_flag = '0;

  // Automated check function for verifying fptoint function
  function void check_fptoint(float f, string description);
    int result;
    int expected;
    result = fptoint(f);
    // Because the behavior of $rtoi isn’t defined when the integer part of the real (or shortreal) value is too big to be represented in a 32-bit signed int, we can’t use it for those cases.
    if (isinfinity(f) || isnan(f)) begin
      expected = 32'h80000000;
    end else begin
      // This assumes shortrealfromfpnumber and fpnumberfromshortreal functions are correct
      expected = $rtoi(shortrealfromfpnumber(f));
    end
    if (result !== expected) begin
      $display("FAIL: %s. Expected: %0d, Got: %0d", description, expected, result);
      error_flag = '1;
    end
  endfunction

  // Automated check function for boolean conditions
  function void check_bool(bit actual, bit expected, string description);
    if (actual !== expected) begin
      $display("FAIL: %s. Expected: %b, Got: %b", description, expected, actual);
      error_flag = '1;
    end
  endfunction

  // Automated check function for shortreal values
  function void check_shortreal(shortreal actual, shortreal expected, shortreal tolerance, string description);
    if ((actual > (expected + tolerance)) && (actual < (expected - tolerance))) begin
      $display("FAIL: %s. Expected: %f, Got: %f", description, expected, actual);
      error_flag = '1;
    end
  endfunction

  initial begin

    // Test fpnumberfromcomponents
    f = fpnumberfromcomponents(0, 8'd127, 23'b10000000000000000000000);
    printfp(f);

    // Test fpnumberfromshortreal
    sr = 3.14;
    f = fpnumberfromshortreal(sr);
    printfp(f);
    // Test shortrealfromfpnumber
    sr = shortrealfromfpnumber(f);
    $display("Shortreal value: %f", sr);

    // Automated checks for iszero, isdenorm, isnan, isinfinity
    f = fpnumberfromcomponents(0, 0, 0);
    check_bool(iszero(f), 1, "Check if zero");
    check_bool(isdenorm(f), 0, "Check if not denormalized");
    check_bool(isnan(f), 0, "Check if not NaN");
    check_bool(isinfinity(f), 0, "Check if not infinity");

    f = fpnumberfromcomponents(0, 0, 23'h1);
    check_bool(isdenorm(f), 1, "Check if denormalized");
    f = fpnumberfromcomponents(0, 8'd255, 23'h1);
    check_bool(isnan(f), 1, "Check if NaN");
    f = fpnumberfromcomponents(0, 8'd255, 0);
    check_bool(isinfinity(f), 1, "Check if positive infinity");
    f = fpnumberfromcomponents(1, 8'd255, 0);
    check_bool(isinfinity(f), 1, "Check if negative infinity");

    // Test with the smallest subnormal number
    f = fpnumberfromcomponents(0, 0, 23'b00000000000000000000001);
    printfp(f);
    // Test with the largest subnormal number
    f = fpnumberfromcomponents(0, 0, 23'b01111111111111111111111);
    printfp(f);
    // Test with the smallest normalized number
    f = fpnumberfromcomponents(0, 8'd1, 0);
    printfp(f);
    // Test with the largest normalized number
    f = fpnumberfromcomponents(0, 8'd254, 23'b11111111111111111111111);
    printfp(f);
    // Test negative infinity
    f = fpnumberfromcomponents(1, 8'd255, 0);
    printfp(f);

    // Test normal number
    f = fpnumberfromcomponents(0, 8'd127, 23'b10000000000000000000000);
    printfp(f);
    sr = shortrealfromfpnumber(f);
    $display("Shortreal value of Normal number: %f", sr);
    // Test denormalized number
    f = fpnumberfromcomponents(0, 0, 23'b1);
    printfp(f);
    // Test infinity
    f = fpnumberfromcomponents(0, 8'd255, 0);
    printfp(f);
    // Test NaN
    f = fpnumberfromcomponents(0, 8'd255, 1);
    printfp(f);

    // Test positive shortreal
    sr = 3.14;
    f = fpnumberfromshortreal(sr);
    printfp(f);
    // Test negative shortreal
    sr = -0.5;
    f = fpnumberfromshortreal( sr);
    printfp(f);
    // Test zero
    sr = 0.0;
    f = fpnumberfromshortreal(sr);
    printfp(f);

    // Test denormalized number
    f = fpnumberfromcomponents(0, 0, 23'b1);
    sr = shortrealfromfpnumber(f);
    $display("Shortreal value of denormalized number: %f", sr);
    // Automated checks for shortrealfromfpnumber
    f = fpnumberfromcomponents(0, 8'd128, 23'b10010001111010111000011);
    sr = shortrealfromfpnumber(f);
    check_shortreal(sr, 3.14, 0.001, "Check shortreal from fpnumber");
    // Test precision loss
    f1 = fpnumberfromcomponents(0, 8'd127, 23'b10000000000000000000000); // Large number
    f2 = fpnumberfromcomponents(0, 8'd127, 0); // Small number that when added to f1 causes precision loss
    f3 = f1 + f2;
    printfp(f3);
    // Test negative zero
    f1 = fpnumberfromcomponents(1, 0, 0); // -0.0
    printfp(f1);
    // Automated checks for comparison between -0.0 and +0.0
    f1 = fpnumberfromcomponents(1, 0, 0); // -0.0
    f2 = fpnumberfromcomponents(0, 0, 0); // +0.0
    check_bool($signed(f1) == $signed(f2), 0, "Check -0.0 == +0.0");
    check_bool($signed(f1) < $signed(f2), 1, "Check -0.0 < +0.0");
    check_bool($signed(f1) > $signed(f2), 0, "Check -0.0 > +0.0");

    // Normal numbers
    f = fpnumberfromshortreal(10.5);
    check_fptoint(f, "Normal positive");
    f = fpnumberfromshortreal(-2.75);
    check_fptoint(f, "Normal negative");
    // Infinity
    f = fpnumberfromcomponents(0, 8'd255, 23'h0);
    check_fptoint(f, "Infinity");
    // Negative infinity
    f = fpnumberfromcomponents(1, 8'd255, 23'h0);
    check_fptoint(f, "Negative Infinity");
    // Largest positive number
    f = fpnumberfromcomponents(0, 8'd158, 23'h0);
    check_fptoint(f, "Largest positive");
    // Smallest negative number
    f = fpnumberfromcomponents(1, 8'd158, 23'h0);
    check_fptoint(f, "Smallest negative");

    for (int i = 0; i < (1<<32); i++) begin
      f = fpnumberfromshortreal(i);
      check_fptoint(f, "Positive number");
    end

    for (int i = 0; i < (1<<32); i++) begin
      f = fpnumberfromshortreal(-i);
      check_fptoint(f, "Negative number");
    end

    for (int i = 0; i < (1<<23); i++) begin
      f = fpnumberfromcomponents(0, 0, i);
      check_fptoint(f, "Denormalized number");
    end

    for (int i = 0; i < (1<<23); i++) begin
      f = fpnumberfromcomponents(0, 8'd255, i);
      check_fptoint(f, "NaN");
    end

    for (int i = 0; i < (1<<23); i++) begin
      f = fpnumberfromcomponents(0, 8'd127, i);
      check_fptoint(f, "Rational number");
    end

    // Check if there were any errors
    if (error_flag === '0) begin
      $display("*** ALL TESTS PASSED ***");
    end else begin
      $display("*** SOME TESTS FAILED ***");
    end

  end

endmodule
