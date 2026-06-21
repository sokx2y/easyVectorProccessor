# Verification plan

1. Generate deterministic A/B and software golden C.
2. Assemble the fully unrolled program and retain `program.lst`.
3. Reset the DUT, run until HALT, and enforce a 500-cycle timeout.
4. Compare vector memory entries 16..23 lane-by-lane against the golden file.
5. Print every result in a machine-readable `RESULT row col value` format.
6. On mismatch print row, column, expected value, and actual value.
7. Dump the complete testbench hierarchy to `dump.vcd`, including PC,
   instruction, decoder controls, RF write enables, MAC signals, and memory
   controls.

Future unit tests should separately cover negative imm5, signed operands,
MOV high/low composition, STORE, scalar MAC reset/accumulate, VL values, and
inactive-lane preservation.

## Pipeline regression

`tb_top_pipelined.sv` instantiates both `top` and `top_pipelined`, runs the
same program and memory images, and compares both C memories against the same
golden output. It also checks that the required VLOAD-to-VMAC forwarding and
VMAC-to-VSTORE forwarding paths activate during the 8x8 program.

`tb_forwarding_unit.sv` independently tests:

- vector source forwarding for VLOAD-to-VMAC;
- old-destination forwarding for immediately consecutive VMAC operations;
- scalar forwarding for LOAD-to-consumer.

Vivado xsim 2023.2 results:

- baseline: PASS, 234 cycles;
- pipeline: PASS, 237 cycles;
- VLOAD-to-VMAC EX forwarding: 64 events;
- VMAC-to-VSTORE forwarding: 8 events;
- forwarding unit test: PASS.

## Host memory regression

`tb_memory_host.sv` disables `$readmemh` and verifies:

- full and byte-strobe ICM writes plus CPU instruction fetch;
- Scalar DCM 32-bit Host mapping, byte strobes, CPU read/write visibility,
  and Host write priority;
- Vector DCM entry/lane addressing, lane preservation, byte strobes,
  CPU whole-vector write followed by Host lane readback, and Host priority.

Expected result: `MEMORY_HOST PASS`. The original matrix tests must remain at
234 baseline cycles and 237 pipeline cycles after the interface extension.

## Deployment controller regression

`tb_processor_host_wrapper.sv` disables all DUT memory initialization and
performs every load/read through the simple Host interface:

1. Load 234 instructions, A, and B.
2. Read back representative locations.
3. Start the pipeline and reject memory/duplicate-START requests while busy.
4. Poll DONE, verify 237 cycles, and compare all 64 C elements.
5. SOFT_RESET without clearing memories.
6. Replace both A and B, start again, and compare against a second golden
   matrix calculated in the testbench.

Expected result: `PROCESSOR_HOST_WRAPPER PASS`, with both runs reporting
237 cycles.

## AXI4-Lite regression

`tb_pynq_axi.sv` verifies AW-first, W-first, and same-cycle AW/W writes,
all control/status registers, read-only and illegal-address SLVERR responses,
unaligned access rejection, dynamic program/data loading, busy memory
protection, duplicate START rejection, and result readback.

Expected result: `PYNQ_AXI PASS`, `AXI PIPELINED_CYCLES=237`, and
`dump_axi.vcd`.

## Vivado implementation verification

The AXI top is synthesized for `xc7z020clg400-1`. The 100 MHz implementation
is retained as a failed timing reference (`WNS=-1.165 ns`), while the 80 MHz
fallback passes setup and hold (`WNS=+0.228 ns`, `WHS=+0.052 ns`) with zero
unrouted nets.

Standalone-IP DRC warnings for missing package pins, I/O standards, and PS7
are expected because no board-level bitstream is generated. Functional
deployment is proven by the AXI xsim testbench rather than an entity-board
test.

## Final Vivado GUI verification

Manual GUI verification was completed on June 21, 2026 using
`vivado/gui_vector_processor/gui_vector_processor.xpr`.

- The saved waveform configuration contains all 31 requested AXI, Host bridge,
  and processor-controller signals.
- Its displayed interval is `0` through `28.086001 us`, with the cursor at
  `28.086000 us`, matching the testbench `$finish`.
- The Vivado Tcl Console reported `AXI PIPELINED_CYCLES=237` and
  `PYNQ_AXI PASS`.

The `USF-XSim` summary saying the simulation ran for `0ns` is a wrapper
reporting artifact: the custom `gui_wave.tcl` performs `run all` internally.
The `$finish` time and PASS output are the authoritative results.
