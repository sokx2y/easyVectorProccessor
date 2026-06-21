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

  // Byte-addressed Host/AXI-Lite register and memory map.
  localparam logic [15:0] HOST_CONTROL_ADDR     = 16'h0000;
  localparam logic [15:0] HOST_STATUS_ADDR      = 16'h0004;
  localparam logic [15:0] HOST_CYCLE_COUNT_ADDR = 16'h0008;
  localparam logic [15:0] HOST_CURRENT_PC_ADDR  = 16'h000c;
  localparam logic [15:0] HOST_VERSION_ADDR     = 16'h0010;
  localparam logic [15:0] HOST_ICM_BASE         = 16'h1000;
  localparam logic [15:0] HOST_ICM_END          = 16'h17ff;
  localparam logic [15:0] HOST_SCALAR_BASE      = 16'h2000;
  localparam logic [15:0] HOST_SCALAR_END       = 16'h23ff;
  localparam logic [15:0] HOST_VECTOR_BASE      = 16'h4000;
  localparam logic [15:0] HOST_VECTOR_END       = 16'h7fff;
  localparam logic [31:0] HOST_VERSION_VALUE    = 32'h0001_0000;

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
