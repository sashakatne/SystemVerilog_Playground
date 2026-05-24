# MemoryZeroController Review

## Design Summary

`mz` combines a datapath and a three-state controller that zeros a memory range.
`ld_high` captures the high bound, `ld_low` captures the low bound, and `zero`
starts an inclusive sweep from low to high. During the sweep, the FSM selects
the counter address, drives zero data, asserts `zero_we`, and increments the
counter.

The controller FSM is:

- `Init`: idle; starts the operation when `zero` is high.
- `Load`: loads the low bound into the counter.
- `Write`: writes zero at the current counter address and increments until
  `cnt_eq` indicates the high bound.

Questa recognized this as one FSM in the farm run. `fsm.png` was generated with
the project-required `visualize` workflow in the same graph-paper pencil style
as `SimpleBusMultiMemory/fsm.png`.

## Farm Simulation Result

Fresh PSU farm run:

```sh
vsim -c -do 'do run.do; quit -f' > transcript.txt
```

Environment: `mo.ece.pdx.edu`, Questa `2021.3_1`, license
`1717@mentor-lic.cecs.pdx.edu`.

Compile/elaboration were clean (`Errors: 0, Warnings: 0`), but the testbench
failed:

- `Test Case 2 Failed: Memory zero error at address 00`
- `Test Case 7 Failed: Normal mode write error after zero mode`
- Final verdict: `Failed testbench (2 test case error(s))`

Coverage from the failing run: filtered total `77.38%`; FSM states `100.00%`;
FSM transitions `75.00%`.

## Review Findings

1. `busy` is not a clean operation-complete handshake. In the current datapath,
   `busy` is `busy_ff | set_busy`, and `set_busy` is driven directly from raw
   `zero` while the FSM is still in `Init`. A zero request can therefore create
   a visible busy pulse before the operation is latched into `Load/Write`.
   The testbench's `wait (busy); wait (!busy);` sequence can complete on that
   pulse instead of waiting for the zero sweep to finish.

2. The farm waveform confirms the race: a later zero request appears while the
   first zero sweep is still in `Write`. That means the directed tests are
   starting the next transaction before the controller has completed the active
   one.

3. The bound registers are transparent latches (`always_latch`). If `addr`
   changes while `ld_high` or `ld_low` is high, the zero range can change within
   the load window. If this is intended to be a synchronous memory controller,
   these should be clocked registers with explicit reset behavior.

## Artifacts

- `fsm.png`: visualize-generated FSM diagram, 1408x768.
- `waveforms.png`: first 340 ns of the failing farm waveform.
- `waveform_samples.csv`: rising-edge samples parsed from the farm VCD.
- `make_artifacts.py`: regenerates only the waveform PNG/CSV artifacts from
  `memoryzero_waveforms.vcd`; it intentionally does not overwrite `fsm.png`.
