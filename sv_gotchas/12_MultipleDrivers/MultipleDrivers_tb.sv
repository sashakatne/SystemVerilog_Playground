// Drives four combinations of (sig_a, sig_b), each held across one full
// clock cycle, then samples both counters on the negative edge. The gotcha
// vector is (sig_a=1, sig_b=1): the fixed version respects the priority and
// writes 0x0A; the buggy version's two NBA writes race in the NBA queue, and
// in Questa the later-scheduled block wins, writing 0x0B.
module top;
  reg        clk;
  reg        sig_a, sig_b;
  wire [7:0] counter_buggy, counter_fixed;
  reg  [7:0] counter_expected;
  integer    vec, n_buggy_caught, n_fixed_clean, errors;

  MultipleDrivers_buggy dut_buggy (.clk(clk), .sig_a(sig_a), .sig_b(sig_b),
                                   .counter(counter_buggy));
  MultipleDrivers_fixed dut_fixed (.clk(clk), .sig_a(sig_a), .sig_b(sig_b),
                                   .counter(counter_fixed));

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    sig_a = 1'b0;
    sig_b = 1'b0;
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;
    counter_expected = 8'd0;

    @(negedge clk);  // settle

    $display("vec  a b  expected  buggy  fixed  verdict");
    for (vec = 0; vec < 4; vec = vec + 1) begin
      case (vec)
        0: begin sig_a = 1'b0; sig_b = 1'b0; counter_expected = counter_expected; end
        1: begin sig_a = 1'b1; sig_b = 1'b0; counter_expected = 8'h0A;           end
        2: begin sig_a = 1'b0; sig_b = 1'b1; counter_expected = 8'h0B;           end
        3: begin sig_a = 1'b1; sig_b = 1'b1; counter_expected = 8'h0A;           end // priority
      endcase
      @(posedge clk);   // DUT samples
      #1;               // settle NBAs

      if (counter_buggy !== counter_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %b %b  %h        %h     %h     GOTCHA OBSERVED (NBA race)",
                 vec, sig_a, sig_b, counter_expected, counter_buggy, counter_fixed);
      end else begin
        $display(" %0d   %b %b  %h        %h     %h     (buggy matches)",
                 vec, sig_a, sig_b, counter_expected, counter_buggy, counter_fixed);
      end

      if (counter_fixed !== counter_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%h want=%h",
                 vec, counter_fixed, counter_expected);
      end else begin
        n_fixed_clean = n_fixed_clean + 1;
      end

      @(negedge clk);   // align to next negedge before changing stimulus
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
