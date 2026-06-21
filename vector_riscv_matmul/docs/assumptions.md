# Assumptions

1. The two supplied course diagrams are the architectural reference. The RTL
   follows their named blocks: PC, ICM, decode/dispatch, immediate generator,
   scalar/vector RF and DCM, MAC units, and writeback muxes. The small blue
   registers in the datapath are treated as timing boundaries; the baseline
   collapses them into one synchronous architectural commit per instruction,
   as permitted by the project brief.
2. ICM is word-addressed and PC increments by one instruction.
3. The baseline is sequential and single-cycle from the architectural point
   of view. Memory reads are combinational; RF and memory writes occur at the
   rising edge.
4. All 16 scalar registers are writable. r0 is not hardwired to zero. r15 is
   the vector-length register.
5. The instruction slide describes each original vector register as
   16 lanes x 8 bits = 128 bits. For the matrix-multiply baseline, the RTL
   keeps the same 16-lane organization but safely widens every physical lane
   to 32 bits. Input B values remain conceptual signed 8-bit weights, while
   VMAC accumulators and stored C values use the full 32-bit lane. This is a
   deliberate width extension, not a different vector organization.
6. VL is read from r15 and set to 8 by the program. Inactive lanes retain
   their prior value.
7. Scalar LOAD/VLOAD imm5 is signed. The example uses only offsets 0..7.
8. Scalar and vector memories have separate address spaces. A starts at
   scalar address 0, B starts at vector address 0, and C starts at vector
   address 16.
9. Current addresses fit in one byte. `MOV` still supports constructing any
   16-bit constant with separate low/high-byte instructions.
10. Arithmetic is signed two's-complement. The selected deterministic test
    values are positive and fit comfortably in 32-bit accumulators.
11. The optional pipeline assumes ICM, Scalar DCM, and Vector DCM have
    one-cycle-stage-compatible combinational reads. No memory-busy condition
    is asserted. Replacing them with synchronous BRAM requires enabling
    stalls or adding another memory pipeline stage.
12. Register files have asynchronous reads and synchronous writes. Correct
    same-cycle dependencies do not rely on write-first behavior; the
    pipelined top explicitly bypasses EX/WB data into both ID and EX.
13. The deployment interface and processor share one clock domain. AXI CDC is
    not required because the Zynq FCLK drives both the AXI slave and core.
14. Host memory windows are legal only outside RUN. ARM_RESET is a core-reset
    interval and is considered non-busy, although normal software waits for
    IDLE or DONE before memory access.
15. SOFT_RESET clears architectural processor state, cycle count, DONE, and
    ACCESS_ERROR but deliberately preserves ICM and DCM contents.
