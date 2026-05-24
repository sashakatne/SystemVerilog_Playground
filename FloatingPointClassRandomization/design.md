# Floating-Point Class Randomization

This directory contains a self-contained SystemVerilog class package for
building and randomizing IEEE-754 single-precision floating-point bit patterns.

## Files

- `floatingpointpkg.sv` defines the packed `float` type, constants for the sign,
  exponent, and fraction widths, component construction, conversion helpers, and
  classification predicates.
- `fpclass.sv` defines package `fpclasspkg` and class `FpNumber`.
- `testbench.sv` is a self-checking randomized testbench with a covergroup and
  VCD dump variables used for waveform plotting.
- `run.do` compiles, elaborates, simulates, saves coverage, and prints coverage
  reports in Questa.
- `fsm.png` shows the verification mode sequence for the class-based design.
- `waveform_samples.csv` is derived from the default-run VCD.
- `waveforms.png` is plotted from those real simulation samples.
- `report.pdf` combines the verification-flow diagram and waveform snapshot.

## Class Interface

`FpNumber` has three randomizable component attributes:

```systemverilog
rand bit sign;
rand bit [EXPONENT_BITS-1:0] exponent;
rand bit [FRACTION_BITS-1:0] fraction;
```

`minexp` and `maxexp` are non-randomized attributes used only by `exprange_c`.
They are unbiased exponent values. For example, `minexp = 1` constrains the
stored exponent field to at least `1 + BIAS`.

The `to_float()` method converts the class attributes into the packed
`floatingpointpkg::float` value used by the helper package.

## Constraints

- `nodenorm_c` prevents denormalized values.
- `alldenorm_c` allows only denormalized values.
- `nonan_c` prevents NaN values.
- `noinf_c` prevents infinity values.
- `exprange_c` constrains the stored exponent field to
  `[minexp + BIAS : maxexp + BIAS]`.

The constructor disables all optional constraints so a default object can be
randomized without conflicting constraint modes. The testbench enables one mode
at a time, then also verifies a combined finite-normal range mode.

## Verification

Run from this directory:

```sh
vsim -c -do 'do run.do; quit -f' > transcript.txt
```

To run a shorter validation:

```sh
vsim -c -do 'set TESTS_PER_MODE 64; do run.do; quit -f' > transcript_smoke.txt
```

The default run performs directed construction/classification checks and six
randomized modes with `TESTS_PER_MODE` samples each. A passing run prints:

```text
No errors -- passed testbench
```

Raw simulator work libraries, waveform databases, and UCDB files are generated
as run artifacts and are not part of the retained source bundle.
