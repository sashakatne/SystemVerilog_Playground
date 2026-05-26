// Drives a per-cycle stimulus pattern. The TB updates `stim` BEFORE each
// negedge, so the fixed (negedge) driver picks up the new value at the
// negedge and writes `d_fixed` via NBA -- stable on the wire well before
// the next posedge. The buggy (posedge) driver writes `d_buggy = stim`
// using BLOCKING on the same posedge the DUT samples on. In Questa's
// resolution order, the DUT's NBA RHS reads `d_buggy` in the Active region
// before the driver's blocking write fires, so the DUT silently samples
// the OLD `d_buggy` and `q_buggy` lags the stim by one cycle.
module top;
  reg     clk;
  reg     stim;
  wire    d_buggy, d_fixed;
  wire    q_buggy, q_fixed;
  reg     q_expected;
  integer cycle, n_buggy_caught, n_fixed_clean, errors;

  SameEdgeRace_buggy drv_buggy (.clk(clk), .start(stim), .d(d_buggy));
  SameEdgeRace_dut   dut_buggy (.clk(clk), .d(d_buggy), .q(q_buggy));

  SameEdgeRace_fixed drv_fixed (.clk(clk), .start(stim), .d(d_fixed));
  SameEdgeRace_dut   dut_fixed (.clk(clk), .d(d_fixed), .q(q_fixed));

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    stim           = 1'b0;
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("cycle  stim  expected_q  q_buggy  q_fixed  verdict");
    for (cycle = 0; cycle < 4; cycle = cycle + 1) begin
      // Set stim BEFORE the next negedge so the fixed driver picks up the
      // correct per-cycle value.
      case (cycle)
        0: stim = 1'b1;
        1: stim = 1'b0;
        2: stim = 1'b1;
        3: stim = 1'b0;
      endcase

      @(negedge clk);    // fixed driver samples stim here (NBA)
      @(posedge clk);    // DUTs sample d here
      #1;                // settle

      // The fixed DUT samples d_fixed which was set at the prior negedge
      // to this cycle's stim. Expected = current stim.
      q_expected = stim;

      if (q_buggy !== q_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display("  %0d    %b     %b           %b        %b       GOTCHA OBSERVED (one-cycle lag)",
                 cycle, stim, q_expected, q_buggy, q_fixed);
      end else begin
        $display("  %0d    %b     %b           %b        %b       (buggy matches)",
                 cycle, stim, q_expected, q_buggy, q_fixed);
      end

      if (q_fixed !== q_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on cycle=%0d  fixed=%b want=%b",
                 cycle, q_fixed, q_expected);
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
