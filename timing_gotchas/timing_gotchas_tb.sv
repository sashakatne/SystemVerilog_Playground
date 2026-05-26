`ifndef VCD_FILE
`define VCD_FILE "timing_gotchas_waveforms.vcd"
`endif

timeunit 1ps;
timeprecision 1ps;

module top;
  localparam int CLOCK_PERIOD_PS = 1000;
  localparam int HOLD_REQ_PS     = 80;
  localparam int SETUP_REQ_PS    = 150;

  logic clk;
  logic rst_n;
  logic launch_d;

  wire min_fast_launch_q;
  wire min_fast_capture_d;
  wire min_fast_capture_q;
  wire min_fast_hold_window;
  wire min_fast_hold_violation;
  wire min_fast_hold_violation_pulse;

  wire min_padded_launch_q;
  wire min_padded_capture_d;
  wire min_padded_capture_q;
  wire min_padded_hold_window;
  wire min_padded_hold_violation;
  wire min_padded_hold_violation_pulse;

  wire max_slow_launch_q;
  wire max_slow_capture_d;
  wire max_slow_capture_q;
  wire max_slow_setup_window;
  wire max_slow_setup_violation;
  wire max_slow_setup_violation_pulse;

  wire max_ok_launch_q;
  wire max_ok_capture_d;
  wire max_ok_capture_q;
  wire max_ok_setup_window;
  wire max_ok_setup_violation;
  wire max_ok_setup_violation_pulse;

  integer min_gotcha_count;
  integer max_gotcha_count;
  integer clean_count;
  integer errors;

  MinDelayHoldDemo #(
    .CONTAM_DELAY_PS(20),
    .HOLD_REQ_PS(HOLD_REQ_PS)
  ) min_fast (
    .clk(clk),
    .rst_n(rst_n),
    .launch_d(launch_d),
    .launch_q(min_fast_launch_q),
    .capture_d(min_fast_capture_d),
    .capture_q(min_fast_capture_q),
    .hold_window(min_fast_hold_window),
    .hold_violation(min_fast_hold_violation),
    .hold_violation_pulse(min_fast_hold_violation_pulse)
  );

  MinDelayHoldDemo #(
    .CONTAM_DELAY_PS(120),
    .HOLD_REQ_PS(HOLD_REQ_PS)
  ) min_padded (
    .clk(clk),
    .rst_n(rst_n),
    .launch_d(launch_d),
    .launch_q(min_padded_launch_q),
    .capture_d(min_padded_capture_d),
    .capture_q(min_padded_capture_q),
    .hold_window(min_padded_hold_window),
    .hold_violation(min_padded_hold_violation),
    .hold_violation_pulse(min_padded_hold_violation_pulse)
  );

  MaxDelaySetupDemo #(
    .PROP_DELAY_PS(920),
    .SETUP_REQ_PS(SETUP_REQ_PS),
    .CLOCK_PERIOD_PS(CLOCK_PERIOD_PS)
  ) max_slow (
    .clk(clk),
    .rst_n(rst_n),
    .launch_d(launch_d),
    .launch_q(max_slow_launch_q),
    .capture_d(max_slow_capture_d),
    .capture_q(max_slow_capture_q),
    .setup_window(max_slow_setup_window),
    .setup_violation(max_slow_setup_violation),
    .setup_violation_pulse(max_slow_setup_violation_pulse)
  );

  MaxDelaySetupDemo #(
    .PROP_DELAY_PS(700),
    .SETUP_REQ_PS(SETUP_REQ_PS),
    .CLOCK_PERIOD_PS(CLOCK_PERIOD_PS)
  ) max_ok (
    .clk(clk),
    .rst_n(rst_n),
    .launch_d(launch_d),
    .launch_q(max_ok_launch_q),
    .capture_d(max_ok_capture_d),
    .capture_q(max_ok_capture_q),
    .setup_window(max_ok_setup_window),
    .setup_violation(max_ok_setup_violation),
    .setup_violation_pulse(max_ok_setup_violation_pulse)
  );

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars(0);
  end

  initial begin
    clk = 1'b0;
    forever #(CLOCK_PERIOD_PS / 2) clk = ~clk;
  end

  always @(posedge min_fast_hold_violation_pulse) begin
    min_gotcha_count = min_gotcha_count + 1;
    $display("GOTCHA OBSERVED min-delay/hold: t=%0t ps path=20 ps hold=%0d ps",
             $time, HOLD_REQ_PS);
  end

  always @(posedge max_slow_setup_violation_pulse) begin
    max_gotcha_count = max_gotcha_count + 1;
    $display("GOTCHA OBSERVED max-delay/setup: t=%0t ps path=920 ps setup=%0d ps",
             $time, SETUP_REQ_PS);
  end

  always @(posedge min_padded_hold_violation_pulse) begin
    errors = errors + 1;
    $display("*** FIX FAILED: padded min-delay path reported hold violation at t=%0t ps", $time);
  end

  always @(posedge max_ok_setup_violation_pulse) begin
    errors = errors + 1;
    $display("*** FIX FAILED: max-delay clean path reported setup violation at t=%0t ps", $time);
  end

  task automatic drive_one_cycle(input logic value);
    begin
      @(negedge clk);
      #100;
      launch_d = value;
    end
  endtask

  initial begin
    min_gotcha_count = 0;
    max_gotcha_count = 0;
    clean_count      = 0;
    errors           = 0;
    rst_n            = 1'b0;
    launch_d         = 1'b0;

    $display("time(ps)  launch_d  min_fast_d  min_padded_d  max_slow_d  max_ok_d");
    #200;
    rst_n = 1'b1;

    drive_one_cycle(1'b1);
    drive_one_cycle(1'b0);
    drive_one_cycle(1'b1);
    drive_one_cycle(1'b0);

    #(CLOCK_PERIOD_PS * 2);

    if (min_gotcha_count == 0) begin
      errors = errors + 1;
      $display("*** Error: min-delay/hold gotcha never triggered");
    end
    if (max_gotcha_count == 0) begin
      errors = errors + 1;
      $display("*** Error: max-delay/setup gotcha never triggered");
    end
    if (!min_padded_hold_violation) clean_count = clean_count + 1;
    else begin
      errors = errors + 1;
      $display("*** Error: padded min-delay path latched a hold violation");
    end
    if (!max_ok_setup_violation) clean_count = clean_count + 1;
    else begin
      errors = errors + 1;
      $display("*** Error: clean max-delay path latched a setup violation");
    end

    if (errors == 0)
      $display("No errors -- passed testbench  (gotcha caught min=%0d max=%0d, clean paths %0d/2)",
               min_gotcha_count, max_gotcha_count, clean_count);
    else
      $display("*** Error: timing gotcha testbench found %0d errors", errors);

    $finish;
  end
endmodule
