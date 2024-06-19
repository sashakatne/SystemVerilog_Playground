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