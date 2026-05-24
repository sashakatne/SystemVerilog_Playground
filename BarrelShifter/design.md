# BarrelShifter

This directory contains a parameterized combinational left barrel shifter. The
default test configuration uses `N=32`, which produces five mux stages controlled
by `ShiftAmount[4:0]`.

## Datapath

`BarrelShifter` chains `$clog2(N)` stages of `N`-bit 2:1 muxes:

- Stage 0 shifts by 16 when `ShiftAmount[4]` is high.
- Stage 1 shifts by 8 when `ShiftAmount[3]` is high.
- Stage 2 shifts by 4 when `ShiftAmount[2]` is high.
- Stage 3 shifts by 2 when `ShiftAmount[1]` is high.
- Stage 4 shifts by 1 when `ShiftAmount[0]` is high.

Each active stage selects a left-shifted copy of the previous stage output.
`ShiftIn` fills the vacated LSB positions. Inactive stages pass the previous
stage value through unchanged.

`stage_flow.png` is a combinational stage-flow diagram. It is intentionally not
named as an FSM diagram because this design stores no state.

## Verification

The self-checking testbench sweeps seven directed input patterns across all 32
shift amounts and both `ShiftIn` polarities, then runs 200 random vectors. Each
transaction compares `Out` against the behavioral reference model and samples
`Expected`, `Match`, and the checked inputs into the VCD.

Run from this directory:

```sh
vsim -c -do 'do run.do; quit -f' > transcript.txt
```

A passing run prints:

```text
Ran 648 checks, 0 errors
No errors -- passed testbench
```

`waveforms.png` is plotted from the simulation VCD through
`make_artifacts.py`; `waveform_samples.csv` retains the checked transaction
samples used by the plot. Raw VCD, WLF, work library, and UCDB outputs are run
artifacts and are not retained.
