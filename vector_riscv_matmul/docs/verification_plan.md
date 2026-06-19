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
