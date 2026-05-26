// One DUT (intentionally stuck at Z on its `actual` output) feeding two
// checker modules in parallel. The golden `expected` is held at 1. After
// running for several clock cycles, the fixed checker has fired once per
// posedge and raised error_flag; the buggy checker has never fired, has
// fire_count==0, and its error_flag is still 0 -- the bug slipped through.
module top;
  reg     clk;
  reg     expected;
  wire    actual;
  wire    error_buggy, error_fixed;
  wire [31:0] fires_buggy, fires_fixed;
  integer cycle, n_buggy_caught, n_fixed_clean, errors;

  VerifierSensitivityMiss_dut    dut       (.clk(clk), .actual(actual));
  VerifierSensitivityMiss_buggy  chk_buggy (.clk(clk), .actual(actual), .expected(expected),
                                            .error_flag(error_buggy),
                                            .fire_count(fires_buggy));
  VerifierSensitivityMiss_fixed  chk_fixed (.clk(clk), .actual(actual), .expected(expected),
                                            .error_flag(error_fixed),
                                            .fire_count(fires_fixed));

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    expected       = 1'b1;
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    // let the DUT settle (no driver, so actual stays Z forever)
    @(negedge clk);

    $display("cycle  fires_buggy  fires_fixed  error_buggy  error_fixed");
    for (cycle = 0; cycle < 6; cycle = cycle + 1) begin
      @(posedge clk);
      #1;
      $display("  %0d      %0d            %0d            %b            %b",
               cycle, fires_buggy, fires_fixed, error_buggy, error_fixed);
    end

    $display("final: buggy fires=%0d errors flagged=%b",   fires_buggy, error_buggy);
    $display("final: fixed fires=%0d errors flagged=%b",   fires_fixed, error_fixed);

    // gotcha: the buggy checker never fired despite the bug being present
    if (fires_buggy == 0 && error_buggy === 1'b0) begin
      n_buggy_caught = 1;
      $display("GOTCHA OBSERVED: buggy checker never fired (signal stuck, @(actual) silent), bug undetected");
    end else begin
      $display("buggy checker did fire %0d times; gotcha not observable this run", fires_buggy);
    end

    // fix should have fired every cycle and flagged the error
    if (fires_fixed >= 6 && error_fixed === 1'b1)
      n_fixed_clean = 1;
    else
      errors = 1;

    if (n_buggy_caught == 0)
      $display("*** Error: gotcha never triggered -- demo is silently passing");
    else if (errors != 0)
      $display("*** Error: fix-version did not flag the bug as expected");
    else
      $display("No errors -- passed testbench  (gotcha caught %0d times, fix clean %0d/%0d)",
               n_buggy_caught, n_fixed_clean, 1);

    $finish;
  end
endmodule
