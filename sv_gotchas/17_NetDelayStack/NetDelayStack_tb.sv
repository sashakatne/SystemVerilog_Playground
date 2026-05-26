// Drives a wide pulse on Y (1 from t=10 to t=25, 15 ns wide). Samples D at
// four checkpoints to make the 3-ns lag of the buggy version observable:
//   t=18: fixed already 1 (since t=17), buggy still 0 (not until t=20)
//   t=22: both 1
//   t=33: fixed already 0 (since t=32), buggy still 1 (until t=35)
//   t=36: both 0
// Two GOTCHA events, two clean matches.
`timescale 1ns/100ps
module top;
  reg     Y;
  wire    D_buggy, D_fixed;
  reg     D_expected;
  integer n_buggy_caught, n_fixed_clean, errors;

  NetDelayStack_buggy dut_buggy (.Y(Y), .D(D_buggy));
  NetDelayStack_fixed dut_fixed (.Y(Y), .D(D_fixed));

  initial begin
    Y = 1'b0;
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("time  Y  D_buggy  D_fixed  expected  verdict");

    #10;  Y = 1'b1;     // rising edge of pulse at t=10

    #8;                 // now t=18
    D_expected = 1'b1;
    if (D_buggy !== D_expected) begin
      n_buggy_caught = n_buggy_caught + 1;
      $display("t=18   %b  %b        %b        %b         GOTCHA OBSERVED (stack adds 3 ns)",
               Y, D_buggy, D_fixed, D_expected);
    end else
      $display("t=18   %b  %b        %b        %b         (match)", Y, D_buggy, D_fixed, D_expected);
    if (D_fixed === D_expected) n_fixed_clean = n_fixed_clean + 1;
    else begin errors = errors + 1; $display("     *** FIX FAILED at t=18"); end

    #4;                 // now t=22
    D_expected = 1'b1;
    if (D_buggy !== D_expected) begin
      n_buggy_caught = n_buggy_caught + 1;
      $display("t=22   %b  %b        %b        %b         GOTCHA OBSERVED",
               Y, D_buggy, D_fixed, D_expected);
    end else
      $display("t=22   %b  %b        %b        %b         (match)", Y, D_buggy, D_fixed, D_expected);
    if (D_fixed === D_expected) n_fixed_clean = n_fixed_clean + 1;
    else begin errors = errors + 1; $display("     *** FIX FAILED at t=22"); end

    #3;                 // now t=25
    Y = 1'b0;           // falling edge at t=25

    #8;                 // now t=33
    D_expected = 1'b0;
    if (D_buggy !== D_expected) begin
      n_buggy_caught = n_buggy_caught + 1;
      $display("t=33   %b  %b        %b        %b         GOTCHA OBSERVED (lag at falling edge)",
               Y, D_buggy, D_fixed, D_expected);
    end else
      $display("t=33   %b  %b        %b        %b         (match)", Y, D_buggy, D_fixed, D_expected);
    if (D_fixed === D_expected) n_fixed_clean = n_fixed_clean + 1;
    else begin errors = errors + 1; $display("     *** FIX FAILED at t=33"); end

    #3;                 // now t=36
    D_expected = 1'b0;
    if (D_buggy !== D_expected) begin
      n_buggy_caught = n_buggy_caught + 1;
      $display("t=36   %b  %b        %b        %b         GOTCHA OBSERVED",
               Y, D_buggy, D_fixed, D_expected);
    end else
      $display("t=36   %b  %b        %b        %b         (match)", Y, D_buggy, D_fixed, D_expected);
    if (D_fixed === D_expected) n_fixed_clean = n_fixed_clean + 1;
    else begin errors = errors + 1; $display("     *** FIX FAILED at t=36"); end

    if (n_buggy_caught == 0)
      $display("*** Error: gotcha never triggered -- demo is silently passing");
    else if (errors != 0)
      $display("*** Error: %0d fix-version mismatches", errors);
    else
      $display("No errors -- passed testbench  (gotcha caught %0d times, fix clean %0d/4)",
               n_buggy_caught, n_fixed_clean);

    $finish;
  end
endmodule
