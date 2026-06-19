`ifndef VECTOR_RISCV_DEFS_SV
`define VECTOR_RISCV_DEFS_SV

package vector_defs;
  parameter int INSTR_WIDTH       = 32;
  parameter int PC_WIDTH          = 16;
  parameter int SCALAR_WIDTH      = 16;
  parameter int ADDR_WIDTH        = 16;
  parameter int VEC_LANES         = 16;
  parameter int LANE_WIDTH        = 8;
  parameter int ACC_WIDTH         = 32;
  parameter int NUM_SCALAR_REGS   = 16;
  parameter int NUM_VECTOR_REGS   = 16;
  parameter int SCALAR_MEM_DEPTH  = 256;
  parameter int VECTOR_MEM_DEPTH  = 256;
  parameter int VECTOR_WIDTH      = VEC_LANES * ACC_WIDTH;

  typedef enum logic [3:0] {
    OP_NOP    = 4'h0,
    OP_LOAD   = 4'h1,
    OP_STORE  = 4'h2,
    OP_MOV    = 4'h3,
    OP_MAC    = 4'h4,
    OP_VLOAD  = 4'h5,
    OP_VSTORE = 4'h6,
    OP_VMACS  = 4'h7,
    OP_HALT   = 4'hf
  } opcode_t;
endpackage

`endif
