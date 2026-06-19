# Simplified Vector RISC-V-Style Processor

This course project implements two compatible versions of a small scalar
processor with a lane-parallel vector extension:

- `rtl/top.sv`: validated non-pipelined, single-cycle baseline.
- `rtl/top_pipelined.sv`: four-stage IF/ID/EX/WB implementation with
  forwarding.

Neither version is a complete RISC-V or RVV implementation. Both execute the
same `program.mem` and support `LOAD`, `STORE`, `MOV`, `MAC`, `VLOAD`,
`VSTORE`, `VMAC-s`, `NOP`, and `HALT`.

The 8x8 matrix multiplication maps one A element to the scalar input, one B
row to a vector input, and one C row to the vector accumulator:

```text
for i = 0..7:
  vr6 = 0
  for k = 0..7:
    vr6 += A[i][k] * B[k][0..7]
  C[i][0..7] = vr6
```

## Layout

- `rtl/`: synthesizable processor modules.
- `asm/`: course-style pseudo assembly.
- `scripts/`: assembler, data generator, and result checker.
- `sim/`: testbench, memory images, run scripts, log, and VCD.
- `docs/`: ISA, assumptions, architecture, verification, and analysis.

The block-by-block comparison with the supplied course figures is documented
in `docs/diagram_alignment.md`.

## Generate and run

From `vector_riscv_matmul`:

```bash
python scripts/gen_test_data.py
python scripts/asm_to_mem.py
cd sim
./run_iverilog.sh
```

On Windows PowerShell, after installing Icarus Verilog:

```powershell
cd sim
.\run_iverilog.ps1
```

Verilator users can run `sim/run_verilator.sh`. Vivado xsim users can run the
commands in `sim/run_xsim.tcl`.

Successful simulation prints `PASS`, writes `sim/output.log`, and creates
`sim/dump.vcd`. Open the VCD with GTKWave or another waveform viewer.

### Select baseline or pipeline

Baseline top and testbench:

```text
top module: top
testbench:  sim/tb_top.sv
```

Four-stage pipeline:

```powershell
cd sim
.\run_pipeline_xsim.ps1
```

or with Icarus Verilog:

```bash
cd sim
./run_pipeline_iverilog.sh
```

The pipeline testbench instantiates both versions, runs the same memory
images, compares both against the same golden C, reports both cycle counts,
and creates `dump_pipeline.vcd`. The current xsim result is 234 baseline
cycles and 237 pipelined cycles, with 64 VLOAD-to-VMAC forwarding events.

## Memory image formats

- `program.mem`: one 32-bit hexadecimal instruction per line.
- `scalar_init.mem`: one 16-bit scalar word per line; A is row-major.
- `vector_init.mem`: one 512-bit vector per line; lane 0 is the least
  significant 32-bit field. Entries 0..7 hold B rows and 16..23 receive C.
- `expected_output.mem`: eight packed 512-bit golden C rows.

## Implementations and omissions

The baseline completes one instruction per cycle through a long combinational
path. The pipeline overlaps four instructions and uses valid bits plus
WB-to-ID/WB-to-EX forwarding. Both use asynchronous educational memory reads,
synchronous writes, and 16 parallel VMAC lanes while r15 selects VL.

There is no branch, cache, privilege state, exception handling, variable
memory latency, or full RVV state. See `docs/microarchitecture.md` and
`docs/performance_notes.md`.
