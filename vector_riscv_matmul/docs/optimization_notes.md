# Optimization notes

Potential next steps, in increasing structural complexity:

1. Keep B rows resident in several vector registers to reduce VLOAD traffic.
2. Add a compact repeat/loop instruction to reduce the unrolled ICM image.
3. Pipeline LOAD/VLOAD/VMAC and add simple valid/hazard control.
4. Add dual-port or banked memories so scalar and vector accesses overlap.
5. Fuse VLOAD+VMAC-s for this matrix dataflow.
6. Add a small matrix loop controller only after the baseline is measured.

For each optimization, compare cycles, Fmax, LUT/FF/DSP/BRAM, and estimated
power against this exact baseline and retain correctness regression tests.
