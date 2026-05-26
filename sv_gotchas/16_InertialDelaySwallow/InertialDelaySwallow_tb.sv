// Drives three pulses of decreasing width onto `a` with `b` held high, then
// samples y_buggy and y_fixed at the expected delayed times. Wide pulses
// (>= 10 ns) appear on both outputs. Pulses narrower than 10 ns are present
// on the transport-style fixed output but SILENTLY ABSENT from the inertial
// buggy output -- that's the gotcha.
//
// Reference behavior is the transport-delay version; the buggy inertial
// output is what makes the trap observable.
`timescale 1ns/100ps
module top;
  reg  a, b;
  wire y_buggy, y_fixed;
  reg  y_expected;
  integer vec, n_buggy_caught, n_fixed_clean, errors;

  InertialDelaySwallow_buggy dut_buggy (.a(a), .b(b), .y(y_buggy));
  InertialDelaySwallow_fixed dut_fixed (.a(a), .b(b), .y(y_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    a = 1'b0;
    b = 1'b1;

    // settle outputs to 0 (inertial needs 10 ns to commit y=0 after t=0)
    #25;

    // -------- Wide pulse: 20 ns wide, well above the 10 ns delay --------
    // a goes 0->1 at t=25, back to 0 at t=45. Both versions should produce
    // a pulse on y between t=35 and t=55.
    a = 1'b1; #20;
    a = 1'b0;
    // sample at t=45+5 = t=50 (middle of the delayed pulse) -- both should see 1
    #5;
    y_expected = 1'b1;
    $display("vec=0  20ns_pulse  @t=%0t  expected=%b buggy=%b fixed=%b",
             $time, y_expected, y_buggy, y_fixed);
    if (y_buggy !== y_expected) n_buggy_caught = n_buggy_caught + 1;
    if (y_fixed !== y_expected) errors = errors + 1; else n_fixed_clean = n_fixed_clean + 1;

    // wait for outputs to drop back to 0
    #30;

    // -------- Narrow pulse: 5 ns wide, well below the 10 ns delay --------
    // a goes 0->1 at t=80, back to 0 at t=85. Transport: produces a 5 ns
    // pulse on y between t=90 and t=95. Inertial: swallows it -- y stays 0.
    a = 1'b1; #5;
    a = 1'b0;
    // sample at t=85+5+2 = t=92 (inside the would-be transport pulse)
    #7;
    y_expected = 1'b1;  // we WANT to see the pulse (transport behavior)
    $display("vec=1  5ns_pulse   @t=%0t  expected=%b buggy=%b fixed=%b",
             $time, y_expected, y_buggy, y_fixed);
    if (y_buggy !== y_expected) begin
      n_buggy_caught = n_buggy_caught + 1;
      $display("     GOTCHA OBSERVED -- inertial swallowed the 5ns pulse");
    end
    if (y_fixed !== y_expected) errors = errors + 1; else n_fixed_clean = n_fixed_clean + 1;

    #30;

    // -------- Very narrow pulse: 3 ns wide --------
    a = 1'b1; #3;
    a = 1'b0;
    #8;   // sample inside the would-be transport pulse window
    y_expected = 1'b1;
    $display("vec=2  3ns_pulse   @t=%0t  expected=%b buggy=%b fixed=%b",
             $time, y_expected, y_buggy, y_fixed);
    if (y_buggy !== y_expected) begin
      n_buggy_caught = n_buggy_caught + 1;
      $display("     GOTCHA OBSERVED -- inertial swallowed the 3ns pulse");
    end
    if (y_fixed !== y_expected) errors = errors + 1; else n_fixed_clean = n_fixed_clean + 1;

    #30;

    if (n_buggy_caught == 0)
      $display("*** Error: gotcha never triggered -- demo is silently passing");
    else if (errors != 0)
      $display("*** Error: %0d fix-version mismatches", errors);
    else
      $display("No errors -- passed testbench  (gotcha caught %0d times, fix clean %0d/%0d)",
               n_buggy_caught, n_fixed_clean, 3);

    $finish;
  end
endmodule
