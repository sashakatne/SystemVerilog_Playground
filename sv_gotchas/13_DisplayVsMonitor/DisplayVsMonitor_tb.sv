// Drives a sequence of distinct values onto d, samples q via two parallel
// checker modules (one reads in Active region, one with #1 delay into the
// next time slot), and asserts the gotcha is observable when the two captures
// disagree at the same posedge.
`timescale 1ns/100ps
module top;
  reg        clk;
  reg  [7:0] d;
  wire [7:0] q;
  wire [7:0] captured_buggy, captured_fixed;
  reg  [7:0] q_expected;
  integer    cycle, n_buggy_caught, n_fixed_clean, errors;

  DisplayVsMonitor_dut   dut       (.clk(clk), .d(d), .q(q));
  DisplayVsMonitor_buggy cap_buggy (.clk(clk), .q(q), .captured(captured_buggy));
  DisplayVsMonitor_fixed cap_fixed (.clk(clk), .q(q), .captured(captured_fixed));

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;   // 10 ns period
  end

  initial begin
    d              = 8'h00;
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    // settle initial X out of q (one posedge of d=0)
    @(negedge clk);

    $display("cycle  d_now  q_after_posedge  buggy_capture  fixed_capture  verdict");
    for (cycle = 0; cycle < 6; cycle = cycle + 1) begin
      // pick a value that differs from previous q, so the gotcha is visible
      d = cycle[7:0] + 8'h10;
      @(posedge clk);    // unblock right at DUT's sampling edge
      #2;                // wait long enough for fixed's #1 to fire and NBA to settle

      // The fixed capture should agree with the settled q. The buggy capture
      // should be the PRE-update q (i.e. the d from the previous cycle, or 0
      // for the first cycle).
      q_expected = d;    // because DUT just sampled d into q

      if (captured_buggy !== q_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display("  %0d     %h     %h               %h             %h            GOTCHA OBSERVED (buggy saw pre-NBA q)",
                 cycle, d, q, captured_buggy, captured_fixed);
      end else begin
        $display("  %0d     %h     %h               %h             %h            (buggy matches)",
                 cycle, d, q, captured_buggy, captured_fixed);
      end

      if (captured_fixed !== q_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on cycle=%0d  fixed=%h want=%h",
                 cycle, captured_fixed, q_expected);
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
               n_buggy_caught, n_fixed_clean, 6);

    $finish;
  end
endmodule
