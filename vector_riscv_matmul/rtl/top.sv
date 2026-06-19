module top (
  input  logic        clk,
  input  logic        rst_n,
  output logic        halted,
  output logic [15:0] dbg_pc,
  output logic [31:0] dbg_instruction,
  output logic        dbg_scalar_rf_we,
  output logic        dbg_vector_rf_we,
  output logic        dbg_scalar_mem_we,
  output logic        dbg_vector_mem_we
);
  import vector_defs::*;

  logic [PC_WIDTH-1:0] pc_value;
  logic [31:0] instruction;
  logic [3:0] opcode, rd, rs1, rs2;
  logic scalar_rf_we, vector_rf_we;
  logic scalar_mem_re, scalar_mem_we, vector_mem_re, vector_mem_we;
  logic scalar_mac_en, vector_mac_en, mac_reset, mov_high_sel, halt;
  logic [2:0] wb_sel;
  logic [SCALAR_WIDTH-1:0] imm5_ext;
  logic [7:0] imm8;
  logic [SCALAR_WIDTH-1:0] scalar_a, scalar_b, scalar_old_rd, vconfig;
  logic [SCALAR_WIDTH-1:0] scalar_mem_data, scalar_wdata, mov_data, scalar_mac_data;
  logic [ADDR_WIDTH-1:0] scalar_addr, vector_addr;
  logic [VECTOR_WIDTH-1:0] vector_old, vector_operand;
  logic [VECTOR_WIDTH-1:0] vector_mem_data, vector_wdata, vector_mac_data;

  pc u_pc(.clk, .rst_n, .enable(!halted), .value(pc_value));
  icm u_icm(.addr(pc_value), .instruction(instruction));
  decoder u_decoder(
    .instruction, .opcode, .rd, .rs1, .rs2, .scalar_rf_we,
    .vector_rf_we, .scalar_mem_re, .scalar_mem_we, .vector_mem_re,
    .vector_mem_we, .scalar_mac_en, .vector_mac_en, .mac_reset,
    .mov_high_sel, .halt, .wb_sel
  );
  imm_gen u_imm_gen(.instruction, .imm5_ext, .imm8);

  scalar_rf u_scalar_rf(
    .clk, .rst_n, .raddr1(rs1), .raddr2(rs2), .raddr_rd(rd), .waddr(rd),
    .we(scalar_rf_we && !halted), .wdata(scalar_wdata),
    .rdata1(scalar_a), .rdata2(scalar_b), .rdata_rd(scalar_old_rd), .vconfig
  );

  assign scalar_addr = scalar_a + imm5_ext;
  scalar_dcm u_scalar_dcm(
    .clk, .re(scalar_mem_re), .we(scalar_mem_we && !halted),
    .addr(scalar_addr), .wdata(scalar_b), .rdata(scalar_mem_data)
  );

  vector_rf u_vector_rf(
    .clk, .rst_n, .raddr1(rd), .raddr2(rs2), .waddr(rd),
    .we(vector_rf_we && !halted), .wdata(vector_wdata),
    .rdata1(vector_old), .rdata2(vector_operand)
  );

  assign vector_addr = scalar_a + imm5_ext;
  vector_dcm u_vector_dcm(
    .clk, .re(vector_mem_re), .we(vector_mem_we && !halted),
    .addr(vector_addr), .wdata(vector_operand), .rdata(vector_mem_data)
  );

  always_comb begin
    if (mov_high_sel)
      mov_data = {imm8, scalar_a[7:0]};
    else
      mov_data = {scalar_a[15:8], imm8};
  end

  scalar_mac u_scalar_mac(
    .reset_acc(mac_reset), .old_acc(scalar_old_rd), .operand_a(scalar_a),
    .operand_b(scalar_b), .result(scalar_mac_data)
  );

  vector_mac u_vector_mac(
    .reset_acc(mac_reset), .scalar(scalar_a), .vl(vconfig),
    .old_acc(vector_old), .vector_operand(vector_operand),
    .result(vector_mac_data)
  );

  scalar_wb_mux u_scalar_wb_mux(
    .sel(wb_sel), .mem_data(scalar_mem_data), .mov_data,
    .mac_data(scalar_mac_data), .out(scalar_wdata)
  );
  vector_wb_mux u_vector_wb_mux(
    .sel(wb_sel), .mem_data(vector_mem_data), .mac_data(vector_mac_data),
    .out(vector_wdata)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      halted <= 1'b0;
    else if (halt)
      halted <= 1'b1;
  end

  assign dbg_pc = pc_value;
  assign dbg_instruction = instruction;
  assign dbg_scalar_rf_we = scalar_rf_we;
  assign dbg_vector_rf_we = vector_rf_we;
  assign dbg_scalar_mem_we = scalar_mem_we;
  assign dbg_vector_mem_we = vector_mem_we;
endmodule
