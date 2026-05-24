# NonOverlappingClockGenerator Review

## Structure

`novckgen` is a structural cross-coupled NAND clock-phase generator. `CK` and
`~CK` feed two NAND gates, each gated by the opposite phase after a six-buffer
chain. The public outputs are `CK1`, `CK2`, and their direct inversions.

## FSM Applicability

No FSM artifact is generated for this module. The design has no clocked storage,
state register, encoded state variable, or `always_ff`/`always @(posedge ...)`
state transition block. Its behavior is structural combinational feedback, so an
FSM diagram would imply sequential state that is not present in the RTL.

## Farm Simulation Artifacts

The farm run used Questa 2021.3_1 and executed:

```text
vsim -c -do 'do run.do; quit -f'
```

The transcript ends with `No errors -- passed testbench`, and the generated VCD
was parsed into:

- `waveform_samples.csv`: sampled `CK`, `CK1`, `CK2`, complements, and derived
  overlap/dead-band flags for the full 1000 ns run.
- `waveforms.png`: first 80 ns of the farm waveform.

The waveform confirms that `CK1 & CK2` never becomes high in RTL simulation.
Because the buffer primitives have no delay annotation, the delay chains collapse
to zero-delay wires in this run; the waveform therefore shows complementary
phases with no visible dead band.
