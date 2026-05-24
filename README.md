# My experiments with SystemVerilog

Welcome to my SystemVerilog Playground! This repository contains a collection of SystemVerilog modules designed for various digital design and verification tasks. Below is an overview of the key modules and their functionalities.

## Main Highlights

### 1. Arbiter
The Arbiter module manages access to a shared resource among multiple requesters, ensuring that only one request is granted at a time based on priority.

- **Files**: `Arbiter.sv`, `Arbiter4Behavioral.sv`, `Arbiter4TB.sv`
- **Testbenches**: `Arbiter4TB.sv`
- **Verification**: Assertions in `assertions.sv` in the folder `ArbiterAssertions`. This file is then bound to the Arbiter module in the `top.sv` testbench in this folder.

### 2. FindFirstOne (FFO)
The FFO module identifies the position of the first '1' in a 32-bit input vector, useful in priority encoders and similar applications.

- **Files**: `FFO32s.sv`, `FFO32ptb.sv`, `FFO32sMealytb.sv`
- **Testbenches**: `FFO32sMealytb.sv`, `FFO32ptb.sv`
- **Verification**: Run `run_moore.do` which will also generate coverage reports.

### 3. Sequential Multiplier
A parameterized sequential multiplier module for multiplying two binary numbers using sequential logic.

- **Files**: `multiplier.sv`
- **Testbenches**: `multtb.sv`

### 4. Braille Decoder
A module that decodes Braille input into readable text.

- **Files**: `BrailleDecoder.sv`
- **Testbenches**: `BrailleDecoderTB.sv`

### 5. Arithmetic Logic Unit (ALU)
A versatile ALU module capable of performing various arithmetic and logical operations. My design contains a cascaded version of an ALU. The folder contains different methodologies to test the design and verify its correctness. I have created a conventional testbench, class-based testbench and UVM testbench.

- **Folder**: CascadedTinyALU

### 6. Non-Overlapping Clock Generator
A module that generates non-overlapping clock signals for a given set of inputs.

- **Folder**: NonOverlappingClockGenerator
- **Files**: `novckgen_structural.sv`, `novckgen_tb.sv`

### 7. Line-Following Robot
A combinational controller that drives the two motors of a line-following robot from five photo-sensors, with `InMotion` and `Error` status outputs. Shipped as both a minimal-SOP dataflow model and a gate-primitive structural model that share one self-checking testbench.

- **Folder**: LineFollowingRobot
- **Files**: `robotdataflow.sv`, `robotstructural.sv`, `testbench.sv`, `design.md`
- **Testbenches**: `testbench.sv` (sweeps all 32 sensor patterns against a behavioural reference; prints `No errors -- passed testbench` on success)
- **Verification**: Run `do run_dataflow.do` to verify the dataflow model, `do run_structural.do` for the structural model. Both compile with `-source -lint` and produce a UCDB.

### 8. Barrel Shifter
A parameterized N-bit left-shift barrel shifter built in behavioural dataflow style. Five stages of N-bit 2:1 muxes — controlled bit-by-bit from `ShiftAmount` — cascade shifts of N/2, N/4, ... 1, with `ShiftIn` replicated into the vacated LSB positions. The 2:1 mux is its own module, instantiated `$clog2(N)` times so a single `N` parameter resizes both the data path and the cascade depth.

- **Folder**: BarrelShifter
- **Files**: `barrelshifter.sv` (contains `Mux2to1` and `BarrelShifter`), `testbench.sv`
- **Testbenches**: `testbench.sv` (module `top`, default `N=32`; sweeps 7 directed patterns × all 32 shift amounts × both `ShiftIn` values plus 200 random vectors against a behavioural reference, prints `No errors -- passed testbench` after 648 self-checks)
- **Verification**: Run `do run.do`. Clean `Errors: 0, Warnings: 0` on every `vlog`/`vopt` stage; produces `BarrelShifter.ucdb` with 100.00% per-instance statement and branch coverage on all five mux instances.

### 9. Adder/Subtractor and Complex Numbers
A parameterized structural add/subtract unit built from full-adder instances, plus a SystemVerilog package for complex numbers backed by `shortreal` real and imaginary components.

- **Folder**: AdderSubtractorComplex
- **Files**: `fulladder.sv`, `addsub.sv`, `complexpkg.sv`, `complexm.sv`
- **Testbenches**: `fulladdertb.sv` exhaustively checks the full adder, `addsubtb.sv` exhaustively checks all default 8-bit add/sub input combinations against a procedural reference, and `complexm.sv` self-checks complex construction, addition, multiplication, printing, and component extraction.
- **Verification**: Run `do run_fulladder.do`, `do run_addsub.do`, and `do run_complex.do`. Each script compiles with `-source -lint`, saves coverage, and the testbench prints `No errors -- passed testbench` on success.

### 10. MIPS Instruction Decoder
A packed-union MIPS instruction decoder that views the same 32-bit word as raw bits, a generic opcode payload, or R/I/J instruction fields.

- **Folder**: MIPSInstructionDecoder
- **Files**: `mipspkg.sv`, `mipstest.sv`
- **Testbench**: `mipstest.sv` imports the package, checks R, I, and J field aliases from packed 32-bit instruction values, and calls `DecodeInstruction` for multiple examples.
- **Verification**: Run `do run.do`. The testbench prints decoded fields and ends with `No errors -- passed testbench` on success.

### 11. SimpleBus Multi-Memory Interface
A SimpleBus processor/memory model that uses a SystemVerilog interface, processor and memory modports, 24-bit addresses, and a generated bank of 64KB memory interfaces selected by the upper address byte.

- **Folder**: SimpleBusMultiMemory
- **Files**: `simplebusif.sv`, `run.do`, `design.md`, `MANIFEST.txt`, `fsm.png`, `waveforms.png`, `report.pdf`
- **Testbench**: `top` in `simplebusif.sv` verifies generated memory selection, read/write transfers, shared local-offset isolation, boundary offsets, and unmapped-base timeout behavior.
- **Verification**: Run `do run.do`. Override the number of memories with `set NUMMEM <count>` before running; the default is 4. The testbench ends with `No errors -- passed testbench` on success.

### 12. Headlamp Button Controller
A synchronous button controller with short-press, hold, and recall outputs. The design uses a four-state one-hot FSM and parameterized timing thresholds.

- **Folder**: HeadlampButtonController
- **Files**: `buttons.sv`, `assertions.sv`, `testbench.sv`, `run.do`, `design.md`, `MANIFEST.txt`, `fsm.png`, `waveforms.png`, `report.pdf`
- **Testbench**: `top` in `testbench.sv` instantiates `Buttons B0`, binds `ButtonAssertions BA0`, and checks reset, short press, immediate re-press, hold threshold, extended hold, idle recall, recall persistence, and recall clear on release.
- **Verification**: Run `do run.do`. The default thresholds are `HOLDTICKS=1000` and `RECALLTICKS=8000`; the testbench ends with `No errors -- passed testbench` on success.

### 13. Floating-Point Class Randomization
A class-based IEEE-754 single-precision bit-pattern generator with randomizable sign, exponent, and fraction attributes plus denormal, NaN, infinity, and exponent-range constraints.

- **Folder**: FloatingPointClassRandomization
- **Files**: `floatingpointpkg.sv`, `fpclass.sv`, `testbench.sv`, `run.do`, `design.md`, `MANIFEST.txt`, `make_artifacts.py`, `fsm.png`, `waveforms.png`, `waveform_samples.csv`, `report.pdf`, `transcript.txt`, `transcript_smoke.txt`
- **Testbench**: `top` in `testbench.sv` checks direct component-to-float construction, directed classification probes, each randomization constraint by mode, and one combined finite ranged-normal mode.
- **Verification**: Run `do run.do`. The default run completes 6005 self-checks with 0 errors and prints `No errors -- passed testbench`.

## Verification

### Assertions
Assertions are used extensively to ensure the correctness of the modules. Key assertions include:
- Valid request and grant vectors
- Single cycle grant production
- No simultaneous grants

### Coverage
Coverage metrics are collected to ensure thorough testing of the modules. Coverage reports can be generated using the provided `.do` files.

## Running Simulations

To run simulations and generate coverage reports, use the provided `.do` files. For example, to run the Arbiter verification:
```sh
cd Arbiter
do run.do
```
