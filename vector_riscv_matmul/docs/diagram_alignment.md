# Course diagram alignment

This note records the direct mapping from the two supplied course diagrams to
the implementation.

## Instruction slide

| Diagram item | RTL / assembler mapping | Status |
|---|---|---|
| `LOAD rd, rs, imm5` | `OP_LOAD`, signed `imm5` address offset | Exact |
| `Store /, rs1, rs2` | `OP_STORE`; unused destination encodes as zero | Exact |
| `MOV rd, imm8, funct1` | `$0` replaces low byte, `$1` replaces high byte | Exact |
| `MAC rd, rs1, rs2, funct1` | `$0` accumulates, `$1` clears destination | Exact |
| `Vload vrd, rs, imm5` | Vector DCM to Vector RF | Exact |
| `Vstore /, rs, vrs` | Vector RF to Vector DCM | Exact |
| `VMAC-s vrd, rs, vrs1, funct1` | Scalar broadcast times vector lanes | Exact |
| `r15 = Vector Config` | r15 provides active vector length, VL | Exact |
| 16 registers x 16 lanes x 8 bits | 16 registers x 16 lanes x 32 bits | Safely widened |

`NOP` and `HALT` are small simulation/control additions. They do not add
general RISC-V or RVV behavior.

## Datapath slide

| Diagram block/path | Project implementation |
|---|---|
| PC increment and ICM | `pc.sv`, `icm.sv` |
| ICM timing boundary to Decode/Dispatch | synchronous PC plus combinational instruction decode |
| Decode/Dispatch | `decoder.sv` |
| Immediate generator | `imm_gen.sv` |
| Immediate/memory scalar writeback MUX | `scalar_wb_mux` in `muxes.sv` |
| Scalar RF and Config Reg | `scalar_rf.sv`, with r15 exposed as `vconfig` |
| Scalar DCM, 16-bit path | `scalar_dcm.sv`, `SCALAR_WIDTH=16` |
| Scalar RF address feed to both DCMs | `scalar_addr` and `vector_addr` in `top.sv` |
| Vector DCM (Weight) | `vector_dcm.sv` |
| Vector Register File | `vector_rf.sv` |
| Parallel MAC blocks | lane loop in `vector_mac.sv`, synthesized as parallel arithmetic |
| Vector source/result selection MUX | `vector_wb_mux` plus explicit RF read ports |
| Vector-domain dashed boundary | vector RF/DCM/MAC modules and their top-level interconnect |

The blue registers are not modeled as a deep pipeline in the baseline.
Architectural state still changes only on clock edges. This keeps the
diagram's synchronous boundaries while avoiding pipeline hazards that the
course brief explicitly allows the baseline to omit.

## Width rationale

Using literal 8-bit accumulator lanes would overflow valid matrix results;
the supplied test already produces values above 127 and 255. Therefore:

- B weights are generated in the intended 8-bit numerical range, and VMAC
  explicitly sign-extends the low 8-bit weight field in each source lane.
- Scalar operands are 16-bit, matching the scalar datapath.
- Products and vector accumulators are held in signed 32-bit lanes.
- Vector memory also has 32-bit lanes so VSTORE preserves C exactly.

This is the smallest functional extension that retains the diagram's
16-register, 16-lane organization and supports correct 8x8 multiplication.
