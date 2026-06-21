# Vivado implementation results

All results below use Vivado 2023.2 and `xc7z020clg400-1`. Generated build
products live under `vivado/build/` and can be recreated with the Tcl scripts
in `scripts/`.

## AXI deployment top

Top: `pynq_vector_processor_ip`

| Metric | Result |
|---|---:|
| Passing clock | 80 MHz (12.5 ns) |
| 100 MHz setup WNS | -1.165 ns |
| 80 MHz setup WNS | +0.228 ns |
| 80 MHz hold WHS | +0.052 ns |
| Slice LUTs | 16,483 / 53,200 (30.98%) |
| Slice registers | 10,597 / 106,400 (9.96%) |
| DSP48E1 | 17 / 220 (7.73%) |
| BRAM tiles | 0 / 140 |
| Routed nets | 100%, zero failed nets |

ICM, Scalar DCM, and Vector DCM infer distributed RAM because their CPU read
ports are asynchronous. BRAM=0 is therefore expected, not evidence that the
memories were optimized away.

The standalone AXI top exposes 116 package ports and therefore reports
`NSTD-1`, `UCIO-1`, and `ZPS7-1`. These are expected because this course flow
does not assign board pins, instantiate the Zynq PS, or generate a bitstream.
They would be resolved only by integrating the IP into a board-level Block
Design.

## Baseline versus pipeline

The comparison uses out-of-context post-route runs. Host and debug top-level
paths are excluded from timing because they are inactive while the processor
executes; their logic remains included in resource counts.

| Metric | Baseline | Pipeline |
|---|---:|---:|
| Program instructions | 234 | 234 |
| Simulation cycles | 234 | 237 |
| 100 MHz WNS | -5.283 ns | -0.042 ns |
| Estimated post-route Fmax | 65.432 MHz | 99.582 MHz |
| Estimated matrix latency | 3.576 us | 2.380 us |
| Slice LUTs | 14,173 | 16,554 |
| Slice registers | 8,492 | 10,310 |
| DSP48E1 | 17 | 17 |
| BRAM tiles | 0 | 0 |
| Vectorless total power at 100 MHz | 0.263 W | 0.244 W |
| Vectorless dynamic power | 0.158 W | 0.139 W |

The estimated speedup is approximately 1.50x. Fmax is calculated from the
post-route worst path as `1000 / (10 ns - WNS)`. It is an estimate rather
than a binary-searched signoff frequency.

The power comparison uses Vivado vectorless propagation. Its confidence is
Medium for the isolated cores and Low for the AXI top, so the numbers are
suitable as estimates only. A precise activity-based result would require a
mapped SAIF from a post-implementation simulation.

## Final verification status

The complete RTL, Host-memory, Host-wrapper, AXI, synthesis, implementation,
timing, power, and Vivado GUI verification flow passed. The final GUI run
completed at `28.086 us`, reported 237 processor cycles, and printed
`PYNQ_AXI PASS`.

## Reproduction

```powershell
vivado -mode batch -source scripts/run_vivado_synth.tcl
vivado -mode batch -source scripts/run_vivado_impl.tcl -tclargs 10.000
vivado -mode batch -source scripts/run_vivado_impl.tcl -tclargs 12.500
vivado -mode batch -source scripts/run_core_benchmark.tcl -tclargs top 10.000
vivado -mode batch -source scripts/run_core_benchmark.tcl -tclargs top_pipelined 10.000
```
