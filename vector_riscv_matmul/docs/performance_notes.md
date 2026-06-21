# Performance notes

## Baseline

The processor is sequential with one architectural instruction per cycle.
VMAC-s computes all active lanes in parallel. The 8x8 program uses VL=8.

The generated program has 234 instructions including HALT:

- 1 VL setup MOV.
- Per C row: 2 initial address MOVs, 1 accumulator reset, 8 LOADs, 8 VLOADs,
  8 VMAC-s operations, 1 output-address MOV, and 1 VSTORE = 29 instructions.
- 8 rows x 29 = 232, plus setup and HALT = 234.

With race-free post-edge sampling, Vivado xsim 2023.2 reports 234 cycles:
one architectural instruction commits per cycle, including HALT.

## Four-stage pipeline

The four-stage version overlaps IF, ID, EX, and WB. With no stalls, an
N-instruction program completes in approximately `N + 3` cycles. The same
234-instruction image reports:

- baseline: 234 cycles;
- pipeline: 237 cycles;
- verified VLOAD-to-VMAC forwarding events: 64.

This result deserves careful interpretation. The existing baseline is already
a single-cycle CPI=1 processor, not a four-cycle multi-cycle processor.
Pipelining therefore does not reduce its cycle count; filling and draining
add three cycles. The intended performance benefit is a shorter clock period:
the long fetch/decode/RF/memory-or-MAC/writeback path is split across four
cycles. Actual wall-clock improvement must be demonstrated by synthesis Fmax:

```text
baseline time  = 234 x baseline clock period
pipeline time  = 237 x pipeline clock period
```

The pipeline wins latency when its achievable period is less than
`234/237`, about 98.7%, of the baseline period. A conventional non-overlapped
four-cycle multi-cycle implementation would instead take roughly 936 cycles,
against which the pipeline gives the expected throughput improvement.

## Bottlenecks

- Fully unrolled code increases ICM traffic and size.
- B rows are reloaded for every output row.
- In the baseline, scalar LOAD, vector VLOAD, and VMAC do not overlap.
- The pipeline overlaps instructions, but RAW dependencies add forwarding
  mux depth and constrain scheduling.
- VMAC accumulator dependence remains a serial dependency between output-row
  updates even when it is forwarded without a stall.
- There is no loop controller or reuse of the eight B vectors across rows.

## Vivado results

Vivado 2023.2 post-route results for `xc7z020clg400-1` are:

| Metric | Baseline | Pipeline |
|---|---:|---:|
| Cycles | 234 | 237 |
| Estimated Fmax | 65.432 MHz | 99.582 MHz |
| Estimated latency | 3.576 us | 2.380 us |
| LUTs | 14,173 | 16,554 |
| FFs | 8,492 | 10,310 |
| DSPs | 17 | 17 |
| BRAM | 0 | 0 |
| Vectorless total power | 0.263 W | 0.244 W |

The measured latency improvement is approximately 1.50x despite the
pipeline's three fill/drain cycles. The pipeline costs about 16.8% more LUTs
and 21.4% more FFs.

These Fmax values are calculated from the post-route critical paths at a
10 ns constraint. Power uses identical device/tool settings and vectorless
activity propagation; it is an estimate, not measurement. Detailed
assumptions and AXI-top results are in `implementation_results.md`.
