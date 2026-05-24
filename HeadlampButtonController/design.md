# Headlamp Button Controller

This directory contains a self-contained SystemVerilog button controller with
bound assertions, a self-checking testbench, coverage collection, and generated
visual artifacts.

## Interface

The design module is `Buttons`:

```systemverilog
module Buttons #(
    parameter int HOLDTICKS = 1000,
    parameter int RECALLTICKS = 8000
) (
    input  logic Clock,
    input  logic Reset,
    input  logic Button,
    output logic Press,
    output logic Hold,
    output logic Recall
);
```

`Reset` is synchronous. `HOLDTICKS` is the number of pressed clock cycles needed
to assert `Hold`; `RECALLTICKS` is the number of released clock cycles needed to
assert `Recall`.

## Behavior

- A short press released before `HOLDTICKS` produces a one-cycle `Press` pulse.
- A long press at or beyond `HOLDTICKS` asserts `Hold` while the button remains
  pressed and does not produce `Press` on release.
- A released button held low for `RECALLTICKS` cycles asserts `Recall`.
- `Recall` remains asserted through the next press and clears on that press
  release.
- Reset clears the FSM, timer, and all outputs.

## FSM

The controller uses four one-hot states:

- `BUTTON_UP` (`4'b0001`) counts low button time and asserts `Recall` after the
  idle threshold.
- `BUTTON_PRESSED` (`4'b0010`) starts the press timer on the first high sample.
- `BUTTON_DOWN` (`4'b0100`) continues the press timer and asserts `Hold` at the
  hold threshold.
- `BUTTON_RELEASED` (`4'b1000`) emits the release behavior, then returns to idle
  or starts a new press.

`fsm.png` shows the implemented state transitions and `report.pdf` includes the
FSM plus the simulation waveform snapshot.

## Verification

`testbench.sv` defines module `top`, instantiates `Buttons B0`, and binds
`ButtonAssertions BA0` into the design. The testbench checks reset, short
presses, immediate re-pressing, exact-threshold long press behavior, extended
hold behavior, idle recall, recall persistence during the next press, and recall
clear on release.

Run these from this directory in Questa:

```sh
vsim -c -do 'do run.do; quit -f' > transcript_default.txt
vsim -c -do 'set HOLDTICKS 4; set RECALLTICKS 10; do run.do; quit -f' > transcript_fast.txt
vsim -c -do 'set HOLDTICKS 4; set RECALLTICKS 10; set ASSERT_RECALLTICKS 8; set EXPECT_ASSERTION_FAILURE 1; do run.do; quit -f' > transcript_mismatch.txt
```

The default and fast runs each complete 18 self-checks with 0 errors and print
`No errors -- passed testbench`. Both passing runs report 100.00% assertion
coverage, 100.00% FSM state coverage, 75.00% FSM transition coverage, and
88.24% filtered total instance coverage.

The mismatch run intentionally sets the assertion recall threshold lower than
the design recall threshold. It preserves the 18 passing self-checks and reports
four `EXPECTED ASSERTION FAILURE` lines, proving the bound checker catches a
timing contract mismatch.

`waveforms.png` is plotted from the fast-run VCD data. Light dotted vertical
guides mark each `Clock` rising edge. Raw simulator dumps and UCDB databases are
intentionally excluded from the directory.
