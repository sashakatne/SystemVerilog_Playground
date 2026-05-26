timeunit 1ps;
timeprecision 1ps;

// Min-delay gotcha: a launch flop feeds a capture flop through a path whose
// contamination delay is shorter than the capture flop hold requirement.
module MinDelayHoldDemo #(
  parameter int CONTAM_DELAY_PS = 20,
  parameter int HOLD_REQ_PS     = 80
) (
  input  logic clk,
  input  logic rst_n,
  input  logic launch_d,
  output logic launch_q,
  output wire  capture_d,
  output logic capture_q,
  output logic hold_window,
  output logic hold_violation,
  output logic hold_violation_pulse
);
  initial begin
    launch_q             = 1'b0;
    capture_q            = 1'b0;
    hold_window          = 1'b0;
    hold_violation       = 1'b0;
    hold_violation_pulse = 1'b0;
  end

  assign #(CONTAM_DELAY_PS) capture_d = launch_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      launch_q    <= 1'b0;
      capture_q   <= 1'b0;
      hold_window <= 1'b0;
    end else begin
      launch_q    <= launch_d;
      capture_q   <= capture_d;
      hold_window <= 1'b1;
      fork
        begin
          #(HOLD_REQ_PS) hold_window <= 1'b0;
        end
      join_none
    end
  end

  always @(capture_d or negedge rst_n) begin
    if (!rst_n) begin
      hold_violation       <= 1'b0;
      hold_violation_pulse <= 1'b0;
    end else if (hold_window) begin
      hold_violation       <= 1'b1;
      hold_violation_pulse <= 1'b1;
      fork
        begin
          #1 hold_violation_pulse <= 1'b0;
        end
      join_none
    end
  end
endmodule

// Max-delay gotcha: a launch flop feeds a capture flop through a path whose
// propagation delay leaves less than SETUP_REQ_PS before the next clock edge.
module MaxDelaySetupDemo #(
  parameter int PROP_DELAY_PS   = 920,
  parameter int SETUP_REQ_PS    = 150,
  parameter int CLOCK_PERIOD_PS = 1000
) (
  input  logic clk,
  input  logic rst_n,
  input  logic launch_d,
  output logic launch_q,
  output wire  capture_d,
  output logic capture_q,
  output logic setup_window,
  output logic setup_violation,
  output logic setup_violation_pulse
);
  initial begin
    launch_q              = 1'b0;
    capture_q             = 1'b0;
    setup_window          = 1'b0;
    setup_violation       = 1'b0;
    setup_violation_pulse = 1'b0;
  end

  assign #(PROP_DELAY_PS) capture_d = launch_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      launch_q     <= 1'b0;
      capture_q    <= 1'b0;
      setup_window <= 1'b0;
    end else begin
      launch_q     <= launch_d;
      capture_q    <= capture_d;
      setup_window <= 1'b0;
      fork
        begin
          #(CLOCK_PERIOD_PS - SETUP_REQ_PS) setup_window <= 1'b1;
          #(SETUP_REQ_PS) setup_window <= 1'b0;
        end
      join_none
    end
  end

  always @(capture_d or negedge rst_n) begin
    if (!rst_n) begin
      setup_violation       <= 1'b0;
      setup_violation_pulse <= 1'b0;
    end else if (setup_window) begin
      setup_violation       <= 1'b1;
      setup_violation_pulse <= 1'b1;
      fork
        begin
          #1 setup_violation_pulse <= 1'b0;
        end
      join_none
    end
  end
endmodule
