# Microarchitecture

## Baseline: `top.sv`

The top level follows the supplied datapath. PC addresses ICM, the fetched
word enters Decode/Dispatch, and ImmGen supplies the immediate path. The
scalar writeback mux selects immediate, Scalar DCM, or scalar-MAC data before
writing Scalar RF. Scalar RF supplies memory addresses and broadcasts the
scalar operand into the vector domain.

Vector DCM is the diagram's weight memory. VLOAD transfers a packed weight
row through the vector writeback mux into Vector RF. VMAC-s reads the low
signed 8-bit weight field of each `vrs1` lane, reads the old 32-bit
destination accumulator, broadcasts one signed scalar from Scalar RF to the
lane MAC array, and returns the accumulated result through the same vector
writeback mux. VSTORE sends the full widened Vector RF value to Vector DCM.

Each non-halt instruction is decoded combinationally and commits at the next
rising edge. LOAD/VLOAD use combinational reads to make the baseline one
instruction per cycle. The diagram's small blue registers are represented by
these synchronous RF/memory/PC commit boundaries rather than separate
pipeline stages, so no hazard machinery is required.

The course diagram labels the original Vector RF as 16 registers, each with
16 x 8-bit lanes. This implementation preserves 16 registers and 16 lanes,
but widens each lane to 32 bits so 8x8 products can accumulate and VSTORE can
retain C without truncation. r15 is the diagram's Config Reg and supplies VL.
The matrix program sets VL=8, so eight lanes are active.

The baseline has no IF/ID, ID/EX, EX/MEM, or MEM/WB registers. Fetch,
decode, RF read, memory/MAC evaluation, and writeback selection all belong to
one instruction's combinational path. At each rising edge that instruction
commits and PC advances to the next word. Consequently LOAD, VLOAD, and
VMAC-s do not overlap with instructions before or after them. The blue
registers in the course datapath are not separate pipeline stages here.

## Four-stage pipeline: `top_pipelined.sv`

The optional optimized top implements the course timing figure directly:

1. **IF**: ICM is addressed by PC; instruction and PC enter IF/ID.
2. **ID / Reg Read / ImmGen**: decode, immediate generation, Scalar RF read,
   Vector RF read, and control generation enter ID/EX.
3. **EX / Mem / MAC**: scalar/vector memory access, MOV construction, scalar
   MAC, or VMAC-s executes. Results enter EX/WB.
4. **WB**: scalar or vector result writes its register file.

Every pipeline register carries `valid`. Reset, bubbles, and the instruction
behind HALT therefore cannot write RF or DCM state. IF/ID stores valid, PC,
and instruction. ID/EX additionally stores decoded register indices,
operands, immediate fields, VL, function bits, and control. EX/WB stores the
destination, computed scalar/vector data, write enables, HALT, PC,
instruction, and opcode.

## Forwarding and hazards

`forwarding_unit.sv` is instantiated twice:

- **WB-to-EX** resolves an immediately preceding producer. This is the
  required physical VLOAD-to-VMAC path: when EX/WB.vrd equals the VMAC
  `vrs1`, loaded vector data replaces the stale ID/EX vector operand.
- **WB-to-ID** resolves a producer that is writing back while a consumer is
  reading RF. This avoids dependence on simulator-specific write-first RF
  behavior.

The same network also forwards scalar LOAD results, MOV/MAC destination
values, the old VMAC accumulator (`vrd`), and VSTORE vector data. Thus:

- `LOAD r3; VLOAD vr5; VMAC-s ... r3, vr5` gets r3 through WB-to-ID and vr5
  through WB-to-EX.
- Consecutive VMAC-s instructions forward the prior accumulator through
  WB-to-EX.
- In the current schedule, successive accumulations are separated by LOAD
  and VLOAD, so the old accumulator commonly arrives through WB-to-ID.
- `VMAC-s; VSTORE` can forward the new vector directly; the current program
  has one MOV between them and therefore uses WB-to-ID.

Memory reads are combinational and finish in one EX cycle, so data hazards
need no stall. `hazard_unit.sv` exposes `stall` for a future synchronous or
variable-latency memory and flushes IF after HALT is decoded. No branch
hazards exist because the ISA has no branch or jump.
