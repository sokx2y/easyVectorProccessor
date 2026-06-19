# Simplified Vector RISC-V-Style Processor

This course project implements a small sequential scalar processor with a
lane-parallel vector extension. It is intentionally not a complete RISC-V or
RVV implementation. The supported operations are `LOAD`, `STORE`, `MOV`,
`MAC`, `VLOAD`, `VSTORE`, `VMAC-s`, `NOP`, and `HALT`.

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

## Memory image formats

- `program.mem`: one 32-bit hexadecimal instruction per line.
- `scalar_init.mem`: one 16-bit scalar word per line; A is row-major.
- `vector_init.mem`: one 512-bit vector per line; lane 0 is the least
  significant 32-bit field. Entries 0..7 hold B rows and 16..23 receive C.
- `expected_output.mem`: eight packed 512-bit golden C rows.

## Baseline and omissions

The design executes one instruction per cycle, has asynchronous educational
memory reads and synchronous writes, and evaluates 16 VMAC lanes in parallel
while r15 selects the active VL (8 for this program). It has no branch,
pipeline, hazards, caches, privilege state, exceptions, or full RVV state.
See `docs/performance_notes.md` and `docs/optimization_notes.md`.
