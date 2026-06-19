# Microarchitecture

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
