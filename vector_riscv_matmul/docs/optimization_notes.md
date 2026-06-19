# Optimization notes

## Implemented optimization: four-stage pipeline

`top_pipelined.sv` implements IF -> ID/RegRead/ImmGen ->
Memory/MAC -> WB and a real VLOAD-to-VMAC bypass. It overlaps the LOAD,
VLOAD, and VMAC instruction streams used by matrix multiplication while
preserving the original ISA and program.

The cost is additional IF/ID, ID/EX, and EX/WB registers, scalar/vector
forwarding muxes, comparators, valid bits, and hazard-control logic. The
512-bit vector pipeline and bypass paths can consume substantial FF/routing
resources. The cycle count is 237 versus the single-cycle baseline's 234;
the optimization is useful only if synthesis confirms the expected Fmax
increase.

## Further options

Potential next steps, in increasing structural complexity:

1. Keep B rows resident in several vector registers to reduce VLOAD traffic.
2. Add a compact repeat/loop instruction to reduce the unrolled ICM image.
3. Register or bank the large vector bypass network to improve routing.
4. Add dual-port or banked memories so more memory operations overlap.
5. Fuse VLOAD+VMAC-s for this matrix dataflow.
6. Add a small matrix loop controller only after the baseline is measured.

For each optimization, compare cycles, Fmax, LUT/FF/DSP/BRAM, and estimated
power against this exact baseline and retain correctness regression tests.
