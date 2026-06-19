# Performance notes

## Baseline

The processor is sequential with one architectural instruction per cycle.
VMAC-s computes all active lanes in parallel. The 8x8 program uses VL=8.

The generated program has 234 instructions including HALT:

- 1 VL setup MOV.
- Per C row: 2 initial address MOVs, 1 accumulator reset, 8 LOADs, 8 VLOADs,
  8 VMAC-s operations, 1 output-address MOV, and 1 VSTORE = 29 instructions.
- 8 rows x 29 = 232, plus setup and HALT = 234.

Vivado xsim 2023.2 reports `cycles=235`; the extra observed cycle is due to
the testbench sampling the registered `halted` output after HALT commits.

## Bottlenecks

- Fully unrolled code increases ICM traffic and size.
- B rows are reloaded for every output row.
- Scalar LOAD, vector VLOAD, and VMAC do not overlap.
- There is no pipeline, loop controller, or dual-port scheduling.

## Synthesis/report placeholders

After selecting a target FPGA, record clock constraint, worst negative slack,
LUT/FF/DSP/BRAM use, and power-estimator assumptions. Do not compare power
without using the same device, clock, activity source, and tool settings.
