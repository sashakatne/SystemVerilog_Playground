# Timing Gotchas

Two self-contained timing demos model the same failure modes STA reports as
minimum-delay and maximum-delay problems.

## Modules

- `MinDelayHoldDemo`: a launch flop drives a capture flop through a configurable
  contamination-delay path. The farm testbench instantiates a 20 ps path against
  an 80 ps hold requirement, then a clean 120 ps padded path.
- `MaxDelaySetupDemo`: a launch flop drives a capture flop through a configurable
  propagation-delay path. The farm testbench instantiates a 920 ps path on a
  1000 ps clock with a 150 ps setup requirement, then a clean 700 ps path.

Both modules expose their data path, active timing window, latched violation
flag, and one-picosecond violation pulse for waveform inspection.

## Circuit Diagram

`circuit_diagram.png` shows the exact four parameterized instances used to
produce the waveform: the failing and clean min-delay lanes, plus the failing
and clean max-delay lanes. The red lanes are the two gotchas that pulse a
violation flag; the green lanes use safer delay values and stay quiet.

## Verification

Run on the PSU ECE farm with:

```sh
vsim -c -do 'do run.do; quit -f'
```

The checked-in `transcript` comes from Questa 2021.3_1 on the PSU farm and ends
with:

```text
No errors -- passed testbench  (gotcha caught min=4 max=4, clean paths 2/2)
```

`timing_gotchas_waveforms.vcd` is the farm VCD. `make_artifacts.py` parses that
VCD into `waveform_samples.csv`, renders `waveforms.png`, and regenerates
`circuit_diagram.png`.
