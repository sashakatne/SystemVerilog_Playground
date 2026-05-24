# Line-Following Robot Controller — Design

## Problem

A small two-wheeled robot follows a dark line on a flat surface. It carries five
photo-sensors `S4 S3 S2 S1 S0` arranged in a row perpendicular to travel, with `S4` on
the far left and `S0` on the far right. A sensor outputs `1` when the surface beneath
it is dark (line present) and `0` when light is reflected (no line).

Two motors drive the wheels:

| ML | MR | Motion        |
|----|----|---------------|
|  1 |  1 | forward       |
|  1 |  0 | turn right    |
|  0 |  1 | turn left     |
|  0 |  0 | halted        |

The controller drives four outputs: `ML`, `MR`, an `InMotion` LED that lights whenever
at least one motor is on, and an `Error` flag that asserts when the line is lost or the
sensor pattern is otherwise inconsistent. The controller is pure combinational logic.

## Behavioural specification

A **valid line** is a contiguous run of `1`s on the sensor bar. The controller acts as
follows:

| Sensor situation                                          | Outputs              |
|-----------------------------------------------------------|----------------------|
| line lost (`00000`)                                       | halt + `Error = 1`   |
| split line — `1`s with a `0` gap in the middle            | halt + `Error = 1`   |
| contiguous line, `S2` on it (straddling)                  | go forward           |
| contiguous line entirely left of centre (in `S3`, `S4`)   | turn left            |
| contiguous line entirely right of centre (in `S1`, `S0`)  | turn right           |

`11111` (all sensors dark) is treated as straddling: the run is contiguous and includes
`S2`, so the robot keeps going forward.

## Full truth table (32 rows)

| `S4 S3 S2 S1 S0` | Case        | ML | MR | InMotion | Error |
|------------------|-------------|----|----|----------|-------|
| `0 0 0 0 0`      | lost        | 0  | 0  | 0        | 1     |
| `0 0 0 0 1`      | right       | 1  | 0  | 1        | 0     |
| `0 0 0 1 0`      | right       | 1  | 0  | 1        | 0     |
| `0 0 0 1 1`      | right       | 1  | 0  | 1        | 0     |
| `0 0 1 0 0`      | straddle    | 1  | 1  | 1        | 0     |
| `0 0 1 0 1`      | split       | 0  | 0  | 0        | 1     |
| `0 0 1 1 0`      | straddle    | 1  | 1  | 1        | 0     |
| `0 0 1 1 1`      | straddle    | 1  | 1  | 1        | 0     |
| `0 1 0 0 0`      | left        | 0  | 1  | 1        | 0     |
| `0 1 0 0 1`      | split       | 0  | 0  | 0        | 1     |
| `0 1 0 1 0`      | split       | 0  | 0  | 0        | 1     |
| `0 1 0 1 1`      | split       | 0  | 0  | 0        | 1     |
| `0 1 1 0 0`      | straddle    | 1  | 1  | 1        | 0     |
| `0 1 1 0 1`      | split       | 0  | 0  | 0        | 1     |
| `0 1 1 1 0`      | straddle    | 1  | 1  | 1        | 0     |
| `0 1 1 1 1`      | straddle    | 1  | 1  | 1        | 0     |
| `1 0 0 0 0`      | left        | 0  | 1  | 1        | 0     |
| `1 0 0 0 1`      | split       | 0  | 0  | 0        | 1     |
| `1 0 0 1 0`      | split       | 0  | 0  | 0        | 1     |
| `1 0 0 1 1`      | split       | 0  | 0  | 0        | 1     |
| `1 0 1 0 0`      | split       | 0  | 0  | 0        | 1     |
| `1 0 1 0 1`      | split       | 0  | 0  | 0        | 1     |
| `1 0 1 1 0`      | split       | 0  | 0  | 0        | 1     |
| `1 0 1 1 1`      | split       | 0  | 0  | 0        | 1     |
| `1 1 0 0 0`      | left        | 0  | 1  | 1        | 0     |
| `1 1 0 0 1`      | split       | 0  | 0  | 0        | 1     |
| `1 1 0 1 0`      | split       | 0  | 0  | 0        | 1     |
| `1 1 0 1 1`      | split       | 0  | 0  | 0        | 1     |
| `1 1 1 0 0`      | straddle    | 1  | 1  | 1        | 0     |
| `1 1 1 0 1`      | split       | 0  | 0  | 0        | 1     |
| `1 1 1 1 0`      | straddle    | 1  | 1  | 1        | 0     |
| `1 1 1 1 1`      | straddle    | 1  | 1  | 1        | 0     |

Counts: 9 straddle, 3 left, 3 right, 17 error (= 1 lost + 16 splits). Total 32.

## K-maps

Five variables are presented as two 4×4 maps, one per value of `S4`. Rows are
`S3 S2` in Gray code, columns are `S1 S0` in Gray code. Cell entries are
the decimal minterm number for reference. A `1` marks an asserted output, `.`
a deasserted one.

### ML (asserted on minterms {1, 2, 3, 4, 6, 7, 12, 14, 15, 28, 30, 31})

```
S4 = 0                        S4 = 1
            S1 S0                          S1 S0
         00  01  11  10                 00  01  11  10
S3 S2 ┌────────────────┐      S3 S2 ┌────────────────┐
  00  │  . [1] [3] [2] │        00  │  .   .   .   . │
  01  │ [4]  . [7] [6] │        01  │  .   .   .   . │
  11  │[12]  .[15][14] │        11  │[28]  .[31][30] │
  10  │  .   .   .   . │        10  │  .   .   .   . │
      └────────────────┘             └────────────────┘
```

Essential prime implicant groupings (each labelled with the literals it pins):

1. The 4-cell quad `{2, 3, 6, 7}` in the `S4=0` map covers the upper-right 2×2 of the
   inner four columns when `S3 = 0`. It is the only PI covering minterm 2.
   → `~S4 · ~S3 · S1`
2. The 4-cell quad `{4, 6, 12, 14}` in the `S4=0` map covers the leftmost column of
   the `S2=1` rows. It is the only PI covering minterm 4.
   → `~S4 · S2 · ~S0`
3. The 4-cell quad `{12, 14, 28, 30}` straddles the two maps along the `S2=1, S0=0`
   line. It is the only PI covering minterm 28.
   → `S3 · S2 · ~S0`
4. The 4-cell quad `{14, 15, 30, 31}` straddles the two maps along the `S3=1, S2=1,
   S1=1` line. It is the only PI covering minterm 31.
   → `S3 · S2 · S1`
5. Minterm 1 sits alone in `S4=0, S3=0, S2=0, S1=0, S0=1`; the only adjacent minterm
   is 3. The pair `{1, 3}` cannot extend further (minterms 9 and 5 are zeros).
   → `~S4 · ~S3 · ~S2 · S0`

All twelve ML-minterms are covered by these five essential PIs, so the minimal SOP is

```
ML = S3·S2·S1
   + ~S4·S2·~S0
   + S3·S2·~S0
   + ~S4·~S3·S1
   + ~S4·~S3·~S2·S0
```

(16 literals across 5 product terms.)

### MR (asserted on minterms {4, 6, 7, 8, 12, 14, 15, 16, 24, 28, 30, 31})

```
S4 = 0                        S4 = 1
            S1 S0                          S1 S0
         00  01  11  10                 00  01  11  10
S3 S2 ┌────────────────┐      S3 S2 ┌────────────────┐
  00  │  .   .   .   . │        00  │[16]  .   .   . │
  01  │ [4]  . [7] [6] │        01  │  .   .   .   . │
  11  │[12]  .[15][14] │        11  │[28]  .[31][30] │
  10  │ [8]  .   .   . │        10  │[24]  .   .   . │
      └────────────────┘             └────────────────┘
```

Essential prime implicants for MR:

1. The quad `{6, 7, 14, 15}` in the `S4=0` map. Only PI covering minterm 7.
   → `~S4 · S2 · S1`
2. The quad `{4, 6, 12, 14}` in the `S4=0` map. Only PI covering minterm 4.
   → `~S4 · S2 · ~S0`
3. The quad `{14, 15, 30, 31}` across both maps. Only PI covering minterm 31.
   → `S3 · S2 · S1`
4. The quad `{8, 12, 24, 28}` across both maps along the `S3=1, S1=0, S0=0` line. Only PI
   covering minterm 8.
   → `S3 · ~S1 · ~S0`
5. Minterm 16 is isolated in `S4=1, S3=0, S2=0, S1=0, S0=0`; the only adjacent minterm is
   24. The pair `{16, 24}` cannot extend further (minterms 0 and 17 are zeros).
   → `S4 · ~S2 · ~S1 · ~S0`

Minimal SOP:

```
MR = ~S4·S2·S1
   + S3·S2·S1
   + ~S4·S2·~S0
   + S3·~S1·~S0
   + S4·~S2·~S1·~S0
```

(16 literals across 5 product terms.)

## InMotion and Error (non-SOP allowed)

`InMotion` is `1` exactly when at least one motor is on. `Error` is its complement:

```
InMotion = ML | MR
Error    = ~(ML | MR) = ~InMotion
```

Equivalently, `Error = 1` iff the sensor pattern is `00000` or has a non-contiguous run
of `1`s — which is exactly the set of patterns for which both motor SOPs evaluate to 0.

## Structural model

The minimal SOP maps cleanly onto a standard two-level AND-OR-INVERT network:

```
                  ┌───────┐
   Sensors[4] ───►│  NOT  ├──► nS4 ──┐
                  └───────┘          │
                  ┌───────┐          │
   Sensors[3] ───►│  NOT  ├──► nS3 ──┤
                  └───────┘          │
                  ┌───────┐          │         (5 ANDs feed each OR;
   Sensors[2] ───►│  NOT  ├──► nS2 ──┼──┐       10 ANDs total)
                  └───────┘          │  │
                  ┌───────┐          │  │
   Sensors[1] ───►│  NOT  ├──► nS1 ──┤  │
                  └───────┘          │  │       ┌───────┐
                  ┌───────┐          │  │       │       │
   Sensors[0] ───►│  NOT  ├──► nS0 ──┘  │       │       │
                  └───────┘             │       │       │
                                        ├──► ┌──┴──┐ ┌──┴──┐
   Sensors[3,2,1] ─────────────► AND ml_p1 ─►│     │ │     │
   nS4, Sensors[2], nS0 ───────► AND ml_p2 ─►│  OR ├─┤     │── ML
   Sensors[3,2], nS0 ──────────► AND ml_p3 ─►│ (5) │ │     │
   nS4, nS3, Sensors[1] ───────► AND ml_p4 ─►│     │ │     │
   nS4, nS3, nS2, Sensors[0] ──► AND ml_p5 ─►│     │ └─────┘
                                              └─────┘
   nS4, Sensors[2,1] ──────────► AND mr_p1 ─► ┌─────┐ ┌─────┐
   Sensors[3,2,1] ─────────────► AND mr_p2 ─►│     │ │     │
   nS4, Sensors[2], nS0 ───────► AND mr_p3 ─►│  OR ├─┤     │── MR
   Sensors[3], nS1, nS0 ───────► AND mr_p4 ─►│ (5) │ │     │
   Sensors[4], nS2, nS1, nS0 ──► AND mr_p5 ─►│     │ │     │
                                              └─────┘ └─────┘
                                                   ┌──────┐
                                         ML, MR ──►│  OR  ├──► InMotion ──► NOT ──► Error
                                                   └──────┘
```

Total primitive count: 6 inverters (5 sensor + 1 for Error) + 10 ANDs + 3 ORs.

## Notes

- The robot prefers continuing straight over turning. Any pattern where `S2 = 1` and the
  rest of the line is contiguous resolves to forward; only when the centre sensor sees
  no line does the controller turn.
- The structural and dataflow models are functionally equivalent; the testbench compares
  the DUT against a separate behavioural Known-Good-Device that re-derives the outputs
  from the contiguity / centre-sensor rules above, so any disagreement signals a typo
  rather than a methodology bug.

## Generated artifacts

- `logic_flow.png` is a combinational logic-flow diagram for the classifier,
  motor-output logic, and derived status signals. It is intentionally not named
  as an FSM diagram because the controller stores no state.
- `waveform_samples.csv` is derived from the dataflow-run simulation VCD and
  contains every checked sensor pattern.
- `waveforms.png` is plotted from those real simulation samples.
- `report.pdf` combines the logic-flow diagram and waveform snapshot.
