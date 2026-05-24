# FindFirstOne_Sequential Review

## Variants

This directory contains three 32-bit find-first-one implementations:

- `FFO32s.sv`: four-state Moore FSM. It loads the input, scans by shifting, and
  returns to `INIT` when the first one is found or after bit 31.
- `FFO32sMealy.sv`: two-state Mealy FSM. It asserts `ready` in `IDLE` and scans
  in `CHECK`, shifting until `SR[31]` or `Count == 31`.
- `FFO32p.sv`: registered LZD tree pipeline. It has pipeline registers but no
  encoded FSM state or transition process.

## FSM Artifacts

- `fsm_moore.png`: generated through the `visualize` skill in the same
  hand-drawn graph-paper style as `SimpleBusMultiMemory/fsm.png`, from the
  one-hot `INIT`, `LOAD`, `EVAL`, and `SHIFT` transitions in `FFO32s.sv`.
- `fsm_mealy.png`: generated through the `visualize` skill in the same
  hand-drawn graph-paper style as `SimpleBusMultiMemory/fsm.png`, from the
  `IDLE` and `CHECK` transitions in `FFO32sMealy.sv`.
- `pipeline_flow.png`: generated instead of an FSM for `FFO32p.sv`, because the
  pipeline has registers but no FSM.

## Farm Simulation Artifacts

All variants were re-run on the farm with Questa 2021.3_1 using the same compile,
optimization, coverage, and run flow as the checked-in `.do` files, with VCD
logging added from Tcl for artifact generation.

- `waveform_moore.png` and `waveform_moore.csv`
- `waveform_mealy.png` and `waveform_mealy.csv`
- `waveform_pipeline.png` and `waveform_pipeline.csv`

The refreshed transcripts all end with `No errors -- passed testbench`.

## Review Notes

- Moore coverage reports 4/4 FSM states covered, but only 5/7 FSM transitions
  covered. The existing test proves the walked one-hot input sequence but does
  not cover every recognized transition.
- The Moore RTL uses manual combinational sensitivity lists. In particular, the
  output block depends on `shift_reg_data` and `counter_out` while only
  sensitive to `state`; using `always_comb` would be safer.
- The pipeline transcript reports 83.33% filtered coverage because the walking
  one-hot test does not fully exercise every generated LZD expression branch.
