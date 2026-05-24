# SimpleBus Multi-Memory Design

This directory contains a self-contained SimpleBus model with a SystemVerilog
interface, one processor-side interface thread, and a generated bank of
memory-side interface threads.

## Protocol

- The processor drives `Strobe`, exactly one of `Read` or `Write`, a 24-bit
  `Addr`, and write data on `Data` for write cycles.
- Each memory interface owns one 64KB address window. `Addr[23:16]` selects
  the memory base address and `Addr[15:0]` selects the local byte offset.
- Only the selected memory interface drives `Ack`. During reads, that memory
  also drives `Data`; during writes, it samples `Data` from the processor.
- `ReadMem` and `WriteMem` are tasks in `processor_interface`, not members of
  the interface.

## Parameters

- `NUMMEM` is a top-level elaboration parameter. It defaults to 4 and must be
  in the range 1 through 256.
- Generated memory instances use base addresses starting at 0 and incrementing
  by 1.
- To override the number of memories in Questa, set the Tcl variable before
  running the script:

```tcl
set NUMMEM 8
do run.do
```

## Verification

The `top` module is a self-checking testbench. It verifies directed read/write
transactions across every generated memory, local address boundary accesses,
isolation between memories that share the same local offset, and timeout
behavior for an unmapped base address when one exists.

Run:

```tcl
do run.do
```

Passing simulation prints:

```text
No errors -- passed testbench
```

## Diagrams

- `fsm.png` is the black-and-white pencil sketch FSM generated from the
  state/transition list.
- `waveforms.png` is rendered from the simulation waveform data. Light dotted
  vertical guides mark each `clk` rising edge.
- `report.pdf` combines the FSM sketch and waveform snapshot. Raw VCD/WLF dumps
  are intentionally excluded.
