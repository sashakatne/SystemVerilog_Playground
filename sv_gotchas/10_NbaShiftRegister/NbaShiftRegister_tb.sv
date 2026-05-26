// Drives a single-cycle impulse on `d` at cycle 0, then holds d=0. Samples
// `out` on the negative edge (away from the DUT's posedge update) for cycles
// 0..5. Expected (3-deep delay) puts the impulse on cycle 3 only. Buggy
// (collapsed) puts it on cycle 0/1 only.
module top;
  reg  clk, d;
  wire out_buggy, out_fixed;
  reg  out_expected;
  integer cycle, n_buggy_caught, n_fixed_clean, errors;

  NbaShiftRegister_buggy dut_buggy (.clk(clk), .d(d), .out(out_buggy));
  NbaShiftRegister_fixed dut_fixed (.clk(clk), .d(d), .out(out_fixed));

  // free-running clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    d              = 1'b0;
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    // Warmup: the fixed shifter starts at X. Three posedges of d=0 are needed
    // to flush X through q1 -> q2 -> out. Wait three negedges (each follows a
    // posedge) before driving the impulse.
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);

    // drive the impulse: d=1 for one full cycle (one posedge samples d=1)
    d = 1'b1;
    @(negedge clk);    // posedge has fired with d=1 -- fixed shifter loaded stage 1
    d = 1'b0;

    // sample over 6 cycles
    $display("cycle  expected  buggy  fixed   verdict");
    for (cycle = 0; cycle < 6; cycle = cycle + 1) begin
      // Only one posedge sampled d=1. With a 3-deep delay line, out=1 appears
      // exactly two more posedges after the impulse posedge -- which is loop
      // cycle 2 (cycles 0..5 sample after posedges immediately following the
      // impulse posedge, the one after that, and so on).
      out_expected = (cycle == 2) ? 1'b1 : 1'b0;

      if (out_buggy !== out_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display("  %0d        %b        %b      %b    GOTCHA OBSERVED",
                 cycle, out_expected, out_buggy, out_fixed);
      end else begin
        $display("  %0d        %b        %b      %b    (buggy matches)",
                 cycle, out_expected, out_buggy, out_fixed);
      end

      if (out_fixed !== out_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on cycle=%0d  fixed=%b want=%b",
                 cycle, out_fixed, out_expected);
      end else begin
        n_fixed_clean = n_fixed_clean + 1;
      end

      @(negedge clk);
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
