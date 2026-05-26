# SystemVerilog Gotcha Gallery

A curriculum of 17 self-contained demos, each one a minimal DUT + testbench + `run.do` that makes a single SystemVerilog "gotcha" from Mark Faust's ECE 571 review (PSU, `sv_review.pdf`) observable on a Questa transcript.

Every demo follows the same shape:

- `NN_Slug_buggy.sv` — exhibits the trap
- `NN_Slug_fixed.sv` — corrected counterpart with the same port list
- `NN_Slug_tb.sv` — single testbench, instantiates both modules side-by-side, drives identical stimulus, and prints the canonical pass line **only if** (a) the buggy version mismatched on at least one vector AND (b) the fixed version matched on every vector. A demo that "passes silently" with the trap hidden is treated as a defect.
- `run.do` — the repo's canonical 6-step Questa script
- `transcript` — captured Questa output
- `MANIFEST.txt` — start/end UTC, exact command, pass verdict

To run a single demo:

```tcl
cd sv_gotchas/01_DanglingWire
do run.do
```

To run all demos non-interactively on the PSU ECE farm:

```bash
bash sv_gotchas/_run_all_on_farm.sh
```

## Catalogue

| NN | Slug | PDF p. | Trap |
|----|------|--------|------|
| 01 | `DanglingWire` | 7 | Undeclared identifier silently becomes 1-bit wire; a structural typo creates a dangling net that propagates X. |
| 02 | `EqualityX` | 28 | `==`/`!=` return X when either operand has X/Z; `if (Y != expected)` never fires for a never-driven Y. |
| 03 | `ConditionalX` | 29 | `?:` with X in the predicate evaluates both arms and bit-blends per the 4-state OR table. |
| 04 | `BitwiseVsLogicalNot` | 30–32 | `if (~Value)` (vector NOT) fires whenever Value ≠ all-1s, not whenever Value is zero — different from `if (!Value)`. |
| 05 | `ShortCircuitSideEffect` | 33 | `A & (B \| f(C))` always calls `f`; `A && (B \|\| f(C))` short-circuits when `A==0`. |
| 06 | `ArithmeticIntDiv` | 34 | `9.0**(1/2)` ≠ 3 because `1/2` integer-divides to 0; `-13 % 4` vs `13 % -4` follow the dividend's sign. |
| 07 | `BitLengthCarry` | 39–41 | `(a+b) >> 1` loses the carry-out; `(a+b+0) >> 1` keeps it because the literal `0` promotes the RHS to 32-bit. |
| 08 | `CaseUnsizedLiteral` | 42 | `case (v) 00:..; 10:..` — `10` is decimal 10, not 2'b10; only `00` and `01` ever match a 2-bit `v`. |
| 09 | `OutOfRangeBitSelect` | 37 | `vec[32]` on a `reg [31:0]` returns X silently — no compile-time error. |
| 10 | `NbaShiftRegister` | 67–70 | Blocking `q1=in; q2=q1; out=q2;` in a clocked block collapses a 3-deep shifter into a single flip-flop. |
| 11 | `CombinationalNba` | 71 | Non-blocking assignment in a combinational `always @*` leaves the output stale by one delta cycle. |
| 12 | `MultipleDrivers` | 107 | Two clocked `always` blocks both assigning the same `reg` is illegal — produces a Questa elaboration warning by design. |
| 13 | `DisplayVsMonitor` | 109–112 | `$display` fires in the Active region (pre-NBA); `$strobe`/`$monitor` in Postponed (settled). Same simulated time, different printed values. |
| 14 | `SameEdgeRace` | 96, 102 | Driving stimulus on the same posedge the DUT samples is a scheduling race; opposite-edge stimulus is the fix. |
| 15 | `VerifierSensitivityMiss` | 103 | `always @(cactual)` checker never fires if a bug holds cactual at X forever; a clock-edge checker catches it. |
| 16 | `InertialDelaySwallow` | 116–118 | `assign #10 D = A & B;` (inertial) deletes input pulses shorter than 10 ns; transport-style intra-assignment delay keeps them. |
| 17 | `NetDelayStack` | 119–120 | `wire #3 D; assign #7 D = Y;` stacks delays inertially, total 10 ns *with* second-stage pulse filtering. |

## Verification gate

Each demo's transcript must satisfy:

1. Every `vlog` / `vopt` ends with `Errors: 0, Warnings: 0`. The one exception is `12_MultipleDrivers`, where the Questa multi-driver warning **is** the demo — the `run.do` carries a `#` comment explaining the accepted warning.
2. The simulation reaches `$finish` on its own — no Fatal, no Tcl-prompt artifact.
3. The transcript ends with the literal line `No errors -- passed testbench  (gotcha caught N times, fix clean M/N)`.
4. At least one `GOTCHA OBSERVED` line is present, and zero `*** FIX FAILED` lines.

## Source

The PDF lives at `sv_gotchas/sv_review.pdf`. The slide numbers in the catalogue map 1:1 to the PDF page numbers.
