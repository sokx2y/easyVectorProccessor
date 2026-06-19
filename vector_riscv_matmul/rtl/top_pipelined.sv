module top_pipelined (
  input  logic         clk,
  input  logic         rst_n,
  output logic         halted,
  output logic [15:0]  dbg_pc,
  output logic         dbg_if_id_valid,
  output logic [31:0]  dbg_if_id_instruction,
  output logic         dbg_id_ex_valid,
  output logic [3:0]   dbg_id_ex_opcode,
  output logic         dbg_ex_wb_valid,
  output logic [3:0]   dbg_ex_wb_opcode,
  output logic         dbg_scalar_rf_we,
  output logic         dbg_vector_rf_we,
  output logic         dbg_scalar_forward,
  output logic         dbg_vector_forward,
  output logic [511:0] dbg_vload_data,
  output logic [511:0] dbg_vmac_operand_before,
  output logic [511:0] dbg_vmac_operand_after,
  output logic [511:0] dbg_vmac_output,
  output logic         dbg_stall,
  output logic         dbg_bubble
);
  import vector_defs::*;

  // Stage 1: IF
  logic [PC_WIDTH-1:0] fetch_pc;
  logic [INSTR_WIDTH-1:0] fetch_instruction;
  logic fetch_stopped;

  // IF/ID
  logic if_id_valid;
  logic [PC_WIDTH-1:0] if_id_pc;
  logic [INSTR_WIDTH-1:0] if_id_instruction;

  // Stage 2: decode and register reads
  logic [3:0] id_opcode, id_rd, id_rs1, id_rs2;
  logic id_scalar_rf_we, id_vector_rf_we;
  logic id_scalar_mem_re, id_scalar_mem_we;
  logic id_vector_mem_re, id_vector_mem_we;
  logic id_scalar_mac_en, id_vector_mac_en;
  logic id_mac_reset, id_mov_high_sel, id_halt;
  logic [2:0] id_wb_sel;
  logic [SCALAR_WIDTH-1:0] id_imm5;
  logic [7:0] id_imm8;
  logic [SCALAR_WIDTH-1:0] rf_scalar_a, rf_scalar_b, rf_scalar_old;
  logic [SCALAR_WIDTH-1:0] rf_vconfig;
  logic [VECTOR_WIDTH-1:0] rf_vector_old, rf_vector_src;
  logic [SCALAR_WIDTH-1:0] id_scalar_a, id_scalar_b, id_scalar_old;
  logic [SCALAR_WIDTH-1:0] id_vconfig;
  logic [VECTOR_WIDTH-1:0] id_vector_old, id_vector_src;
  logic id_scalar_forward, id_vector_forward;

  // ID/EX
  logic id_ex_valid;
  logic [PC_WIDTH-1:0] id_ex_pc;
  logic [INSTR_WIDTH-1:0] id_ex_instruction;
  logic [3:0] id_ex_opcode, id_ex_rd, id_ex_rs1, id_ex_rs2;
  logic [SCALAR_WIDTH-1:0] id_ex_scalar_a, id_ex_scalar_b;
  logic [SCALAR_WIDTH-1:0] id_ex_scalar_old, id_ex_vconfig;
  logic [VECTOR_WIDTH-1:0] id_ex_vector_old, id_ex_vector_src;
  logic [SCALAR_WIDTH-1:0] id_ex_imm5;
  logic [7:0] id_ex_imm8;
  logic id_ex_scalar_rf_we, id_ex_vector_rf_we;
  logic id_ex_scalar_mem_re, id_ex_scalar_mem_we;
  logic id_ex_vector_mem_re, id_ex_vector_mem_we;
  logic id_ex_mac_reset, id_ex_mov_high_sel, id_ex_halt;
  logic [2:0] id_ex_wb_sel;

  // Stage 3: EX / memory / MAC, after forwarding
  logic [SCALAR_WIDTH-1:0] ex_scalar_a, ex_scalar_b, ex_scalar_old;
  logic [SCALAR_WIDTH-1:0] ex_vconfig;
  logic [VECTOR_WIDTH-1:0] ex_vector_old, ex_vector_src;
  logic ex_scalar_forward, ex_vector_forward;
  logic [ADDR_WIDTH-1:0] ex_scalar_addr, ex_vector_addr;
  logic [SCALAR_WIDTH-1:0] scalar_mem_rdata;
  logic [VECTOR_WIDTH-1:0] vector_mem_rdata;
  logic [SCALAR_WIDTH-1:0] ex_mov_data, ex_scalar_mac_data;
  logic [VECTOR_WIDTH-1:0] ex_vector_mac_data;
  logic [SCALAR_WIDTH-1:0] ex_scalar_wb_data;
  logic [VECTOR_WIDTH-1:0] ex_vector_wb_data;

  // EX/WB
  logic ex_wb_valid;
  logic [PC_WIDTH-1:0] ex_wb_pc;
  logic [INSTR_WIDTH-1:0] ex_wb_instruction;
  logic [3:0] ex_wb_opcode, ex_wb_rd;
  logic [SCALAR_WIDTH-1:0] ex_wb_scalar_data;
  logic [VECTOR_WIDTH-1:0] ex_wb_vector_data;
  logic ex_wb_scalar_rf_we, ex_wb_vector_rf_we, ex_wb_halt;

  logic stall, flush_if;

  pc u_pc(
    .clk, .rst_n,
    .enable(!fetch_stopped && !stall),
    .value(fetch_pc)
  );
  icm u_icm(.addr(fetch_pc), .instruction(fetch_instruction));

  if_id_reg u_if_id(
    .clk, .rst_n, .enable(!stall), .flush(flush_if),
    .valid_in(!fetch_stopped), .pc_in(fetch_pc),
    .instruction_in(fetch_instruction),
    .valid_out(if_id_valid), .pc_out(if_id_pc),
    .instruction_out(if_id_instruction)
  );

  decoder u_decoder(
    .instruction(if_id_instruction), .opcode(id_opcode), .rd(id_rd),
    .rs1(id_rs1), .rs2(id_rs2), .scalar_rf_we(id_scalar_rf_we),
    .vector_rf_we(id_vector_rf_we), .scalar_mem_re(id_scalar_mem_re),
    .scalar_mem_we(id_scalar_mem_we), .vector_mem_re(id_vector_mem_re),
    .vector_mem_we(id_vector_mem_we), .scalar_mac_en(id_scalar_mac_en),
    .vector_mac_en(id_vector_mac_en), .mac_reset(id_mac_reset),
    .mov_high_sel(id_mov_high_sel), .halt(id_halt), .wb_sel(id_wb_sel)
  );
  imm_gen u_imm_gen(
    .instruction(if_id_instruction), .imm5_ext(id_imm5), .imm8(id_imm8)
  );

  scalar_rf u_scalar_rf(
    .clk, .rst_n, .raddr1(id_rs1), .raddr2(id_rs2), .raddr_rd(id_rd),
    .waddr(ex_wb_rd), .we(ex_wb_valid && ex_wb_scalar_rf_we && !halted),
    .wdata(ex_wb_scalar_data), .rdata1(rf_scalar_a),
    .rdata2(rf_scalar_b), .rdata_rd(rf_scalar_old), .vconfig(rf_vconfig)
  );
  vector_rf u_vector_rf(
    .clk, .rst_n, .raddr1(id_rd), .raddr2(id_rs2),
    .waddr(ex_wb_rd), .we(ex_wb_valid && ex_wb_vector_rf_we && !halted),
    .wdata(ex_wb_vector_data), .rdata1(rf_vector_old),
    .rdata2(rf_vector_src)
  );

  // WB-to-ID bypass handles dependencies two instructions apart, where the
  // consumer is reading registers during the producer's WB cycle.
  forwarding_unit u_id_forwarding(
    .producer_valid(ex_wb_valid),
    .producer_scalar_we(ex_wb_scalar_rf_we),
    .producer_vector_we(ex_wb_vector_rf_we),
    .producer_rd(ex_wb_rd),
    .producer_scalar_data(ex_wb_scalar_data),
    .producer_vector_data(ex_wb_vector_data),
    .consumer_rs1(id_rs1), .consumer_rs2(id_rs2), .consumer_rd(id_rd),
    .scalar_a_in(rf_scalar_a), .scalar_b_in(rf_scalar_b),
    .scalar_old_rd_in(rf_scalar_old), .vector_old_in(rf_vector_old),
    .vector_src_in(rf_vector_src), .scalar_a_out(id_scalar_a),
    .scalar_b_out(id_scalar_b), .scalar_old_rd_out(id_scalar_old),
    .vector_old_out(id_vector_old), .vector_src_out(id_vector_src),
    .scalar_forward(id_scalar_forward), .vector_forward(id_vector_forward)
  );

  always_comb begin
    id_vconfig = rf_vconfig;
    if (ex_wb_valid && ex_wb_scalar_rf_we && ex_wb_rd == 4'd15)
      id_vconfig = ex_wb_scalar_data;
  end

  id_ex_reg u_id_ex(
    .clk, .rst_n, .enable(!stall), .flush(1'b0),
    .valid_in(if_id_valid), .pc_in(if_id_pc),
    .instruction_in(if_id_instruction), .opcode_in(id_opcode),
    .rd_in(id_rd), .rs1_in(id_rs1), .rs2_in(id_rs2),
    .scalar_a_in(id_scalar_a), .scalar_b_in(id_scalar_b),
    .scalar_old_rd_in(id_scalar_old), .vconfig_in(id_vconfig),
    .vector_old_in(id_vector_old), .vector_src_in(id_vector_src),
    .imm5_in(id_imm5), .imm8_in(id_imm8),
    .scalar_rf_we_in(id_scalar_rf_we),
    .vector_rf_we_in(id_vector_rf_we),
    .scalar_mem_re_in(id_scalar_mem_re),
    .scalar_mem_we_in(id_scalar_mem_we),
    .vector_mem_re_in(id_vector_mem_re),
    .vector_mem_we_in(id_vector_mem_we),
    .mac_reset_in(id_mac_reset), .mov_high_sel_in(id_mov_high_sel),
    .halt_in(id_halt), .wb_sel_in(id_wb_sel),
    .valid_out(id_ex_valid), .pc_out(id_ex_pc),
    .instruction_out(id_ex_instruction), .opcode_out(id_ex_opcode),
    .rd_out(id_ex_rd), .rs1_out(id_ex_rs1), .rs2_out(id_ex_rs2),
    .scalar_a_out(id_ex_scalar_a), .scalar_b_out(id_ex_scalar_b),
    .scalar_old_rd_out(id_ex_scalar_old), .vconfig_out(id_ex_vconfig),
    .vector_old_out(id_ex_vector_old), .vector_src_out(id_ex_vector_src),
    .imm5_out(id_ex_imm5), .imm8_out(id_ex_imm8),
    .scalar_rf_we_out(id_ex_scalar_rf_we),
    .vector_rf_we_out(id_ex_vector_rf_we),
    .scalar_mem_re_out(id_ex_scalar_mem_re),
    .scalar_mem_we_out(id_ex_scalar_mem_we),
    .vector_mem_re_out(id_ex_vector_mem_re),
    .vector_mem_we_out(id_ex_vector_mem_we),
    .mac_reset_out(id_ex_mac_reset),
    .mov_high_sel_out(id_ex_mov_high_sel),
    .halt_out(id_ex_halt), .wb_sel_out(id_ex_wb_sel)
  );

  // WB-to-EX bypass handles immediately adjacent dependencies, including
  // the required VLOAD -> VMAC-s path.
  forwarding_unit u_ex_forwarding(
    .producer_valid(ex_wb_valid),
    .producer_scalar_we(ex_wb_scalar_rf_we),
    .producer_vector_we(ex_wb_vector_rf_we),
    .producer_rd(ex_wb_rd),
    .producer_scalar_data(ex_wb_scalar_data),
    .producer_vector_data(ex_wb_vector_data),
    .consumer_rs1(id_ex_rs1), .consumer_rs2(id_ex_rs2),
    .consumer_rd(id_ex_rd), .scalar_a_in(id_ex_scalar_a),
    .scalar_b_in(id_ex_scalar_b), .scalar_old_rd_in(id_ex_scalar_old),
    .vector_old_in(id_ex_vector_old), .vector_src_in(id_ex_vector_src),
    .scalar_a_out(ex_scalar_a), .scalar_b_out(ex_scalar_b),
    .scalar_old_rd_out(ex_scalar_old), .vector_old_out(ex_vector_old),
    .vector_src_out(ex_vector_src), .scalar_forward(ex_scalar_forward),
    .vector_forward(ex_vector_forward)
  );

  always_comb begin
    ex_vconfig = id_ex_vconfig;
    if (ex_wb_valid && ex_wb_scalar_rf_we && ex_wb_rd == 4'd15)
      ex_vconfig = ex_wb_scalar_data;
  end

  assign ex_scalar_addr = ex_scalar_a + id_ex_imm5;
  assign ex_vector_addr = ex_scalar_a + id_ex_imm5;

  scalar_dcm u_scalar_dcm(
    .clk, .re(id_ex_valid && id_ex_scalar_mem_re),
    .we(id_ex_valid && id_ex_scalar_mem_we && !halted),
    .addr(ex_scalar_addr), .wdata(ex_scalar_b), .rdata(scalar_mem_rdata)
  );
  vector_dcm u_vector_dcm(
    .clk, .re(id_ex_valid && id_ex_vector_mem_re),
    .we(id_ex_valid && id_ex_vector_mem_we && !halted),
    .addr(ex_vector_addr), .wdata(ex_vector_src), .rdata(vector_mem_rdata)
  );

  always_comb begin
    if (id_ex_mov_high_sel)
      ex_mov_data = {id_ex_imm8, ex_scalar_old[7:0]};
    else
      ex_mov_data = {ex_scalar_old[15:8], id_ex_imm8};
  end

  scalar_mac u_scalar_mac(
    .reset_acc(id_ex_mac_reset), .old_acc(ex_scalar_old),
    .operand_a(ex_scalar_a), .operand_b(ex_scalar_b),
    .result(ex_scalar_mac_data)
  );
  vector_mac u_vector_mac(
    .reset_acc(id_ex_mac_reset), .scalar(ex_scalar_a),
    .vl(ex_vconfig), .old_acc(ex_vector_old),
    .vector_operand(ex_vector_src), .result(ex_vector_mac_data)
  );
  scalar_wb_mux u_scalar_wb_mux(
    .sel(id_ex_wb_sel), .mem_data(scalar_mem_rdata),
    .mov_data(ex_mov_data), .mac_data(ex_scalar_mac_data),
    .out(ex_scalar_wb_data)
  );
  vector_wb_mux u_vector_wb_mux(
    .sel(id_ex_wb_sel), .mem_data(vector_mem_rdata),
    .mac_data(ex_vector_mac_data), .out(ex_vector_wb_data)
  );

  ex_wb_reg u_ex_wb(
    .clk, .rst_n, .valid_in(id_ex_valid), .pc_in(id_ex_pc),
    .instruction_in(id_ex_instruction), .opcode_in(id_ex_opcode),
    .rd_in(id_ex_rd), .scalar_wb_data_in(ex_scalar_wb_data),
    .vector_wb_data_in(ex_vector_wb_data),
    .scalar_rf_we_in(id_ex_scalar_rf_we),
    .vector_rf_we_in(id_ex_vector_rf_we), .halt_in(id_ex_halt),
    .valid_out(ex_wb_valid), .pc_out(ex_wb_pc),
    .instruction_out(ex_wb_instruction), .opcode_out(ex_wb_opcode),
    .rd_out(ex_wb_rd), .scalar_wb_data_out(ex_wb_scalar_data),
    .vector_wb_data_out(ex_wb_vector_data),
    .scalar_rf_we_out(ex_wb_scalar_rf_we),
    .vector_rf_we_out(ex_wb_vector_rf_we), .halt_out(ex_wb_halt)
  );

  hazard_unit u_hazard_unit(
    .halt_in_id(if_id_valid && id_halt), .memory_busy(1'b0),
    .stall(stall), .flush_if(flush_if)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fetch_stopped <= 1'b0;
      halted <= 1'b0;
    end else begin
      if (if_id_valid && id_halt)
        fetch_stopped <= 1'b1;
      if (ex_wb_valid && ex_wb_halt)
        halted <= 1'b1;
    end
  end

  assign dbg_pc = fetch_pc;
  assign dbg_if_id_valid = if_id_valid;
  assign dbg_if_id_instruction = if_id_instruction;
  assign dbg_id_ex_valid = id_ex_valid;
  assign dbg_id_ex_opcode = id_ex_opcode;
  assign dbg_ex_wb_valid = ex_wb_valid;
  assign dbg_ex_wb_opcode = ex_wb_opcode;
  assign dbg_scalar_rf_we = ex_wb_valid && ex_wb_scalar_rf_we;
  assign dbg_vector_rf_we = ex_wb_valid && ex_wb_vector_rf_we;
  assign dbg_scalar_forward = id_scalar_forward || ex_scalar_forward;
  assign dbg_vector_forward = id_vector_forward || ex_vector_forward;
  assign dbg_vload_data = vector_mem_rdata;
  assign dbg_vmac_operand_before = id_ex_vector_src;
  assign dbg_vmac_operand_after = ex_vector_src;
  assign dbg_vmac_output = ex_vector_mac_data;
  assign dbg_stall = stall;
  assign dbg_bubble = !if_id_valid || !id_ex_valid || !ex_wb_valid;
endmodule
