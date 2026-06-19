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
