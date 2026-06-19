// Four-stage pipeline registers. Valid bits prevent reset/flush bubbles from
// changing architectural state.

module if_id_reg #(
  parameter int PC_WIDTH = 16,
  parameter int INSTR_WIDTH = 32
) (
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   enable,
  input  logic                   flush,
  input  logic                   valid_in,
  input  logic [PC_WIDTH-1:0]    pc_in,
  input  logic [INSTR_WIDTH-1:0] instruction_in,
  output logic                   valid_out,
  output logic [PC_WIDTH-1:0]    pc_out,
  output logic [INSTR_WIDTH-1:0] instruction_out
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || flush) begin
      valid_out       <= 1'b0;
      pc_out          <= '0;
      instruction_out <= '0;
    end else if (enable) begin
      valid_out       <= valid_in;
      pc_out          <= pc_in;
      instruction_out <= instruction_in;
    end
  end
endmodule

module id_ex_reg #(
  parameter int PC_WIDTH = 16,
  parameter int INSTR_WIDTH = 32,
  parameter int SCALAR_WIDTH = 16,
  parameter int VECTOR_WIDTH = 512
) (
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    enable,
  input  logic                    flush,
  input  logic                    valid_in,
  input  logic [PC_WIDTH-1:0]     pc_in,
  input  logic [INSTR_WIDTH-1:0]  instruction_in,
  input  logic [3:0]              opcode_in,
  input  logic [3:0]              rd_in,
  input  logic [3:0]              rs1_in,
  input  logic [3:0]              rs2_in,
  input  logic [SCALAR_WIDTH-1:0] scalar_a_in,
  input  logic [SCALAR_WIDTH-1:0] scalar_b_in,
  input  logic [SCALAR_WIDTH-1:0] scalar_old_rd_in,
  input  logic [SCALAR_WIDTH-1:0] vconfig_in,
  input  logic [VECTOR_WIDTH-1:0] vector_old_in,
  input  logic [VECTOR_WIDTH-1:0] vector_src_in,
  input  logic [SCALAR_WIDTH-1:0] imm5_in,
  input  logic [7:0]              imm8_in,
  input  logic                    scalar_rf_we_in,
  input  logic                    vector_rf_we_in,
  input  logic                    scalar_mem_re_in,
  input  logic                    scalar_mem_we_in,
  input  logic                    vector_mem_re_in,
  input  logic                    vector_mem_we_in,
  input  logic                    mac_reset_in,
  input  logic                    mov_high_sel_in,
  input  logic                    halt_in,
  input  logic [2:0]              wb_sel_in,
  output logic                    valid_out,
  output logic [PC_WIDTH-1:0]     pc_out,
  output logic [INSTR_WIDTH-1:0]  instruction_out,
  output logic [3:0]              opcode_out,
  output logic [3:0]              rd_out,
  output logic [3:0]              rs1_out,
  output logic [3:0]              rs2_out,
  output logic [SCALAR_WIDTH-1:0] scalar_a_out,
  output logic [SCALAR_WIDTH-1:0] scalar_b_out,
  output logic [SCALAR_WIDTH-1:0] scalar_old_rd_out,
  output logic [SCALAR_WIDTH-1:0] vconfig_out,
  output logic [VECTOR_WIDTH-1:0] vector_old_out,
  output logic [VECTOR_WIDTH-1:0] vector_src_out,
  output logic [SCALAR_WIDTH-1:0] imm5_out,
  output logic [7:0]              imm8_out,
  output logic                    scalar_rf_we_out,
  output logic                    vector_rf_we_out,
  output logic                    scalar_mem_re_out,
  output logic                    scalar_mem_we_out,
  output logic                    vector_mem_re_out,
  output logic                    vector_mem_we_out,
  output logic                    mac_reset_out,
  output logic                    mov_high_sel_out,
  output logic                    halt_out,
  output logic [2:0]              wb_sel_out
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || flush) begin
      valid_out <= 1'b0;
      pc_out <= '0;
      instruction_out <= '0;
      opcode_out <= '0;
      rd_out <= '0;
      rs1_out <= '0;
      rs2_out <= '0;
      scalar_a_out <= '0;
      scalar_b_out <= '0;
      scalar_old_rd_out <= '0;
      vconfig_out <= '0;
      vector_old_out <= '0;
      vector_src_out <= '0;
      imm5_out <= '0;
      imm8_out <= '0;
      scalar_rf_we_out <= 1'b0;
      vector_rf_we_out <= 1'b0;
      scalar_mem_re_out <= 1'b0;
      scalar_mem_we_out <= 1'b0;
      vector_mem_re_out <= 1'b0;
      vector_mem_we_out <= 1'b0;
      mac_reset_out <= 1'b0;
      mov_high_sel_out <= 1'b0;
      halt_out <= 1'b0;
      wb_sel_out <= '0;
    end else if (enable) begin
      valid_out <= valid_in;
      pc_out <= pc_in;
      instruction_out <= instruction_in;
      opcode_out <= opcode_in;
      rd_out <= rd_in;
      rs1_out <= rs1_in;
      rs2_out <= rs2_in;
      scalar_a_out <= scalar_a_in;
      scalar_b_out <= scalar_b_in;
      scalar_old_rd_out <= scalar_old_rd_in;
      vconfig_out <= vconfig_in;
      vector_old_out <= vector_old_in;
      vector_src_out <= vector_src_in;
      imm5_out <= imm5_in;
      imm8_out <= imm8_in;
      scalar_rf_we_out <= scalar_rf_we_in;
      vector_rf_we_out <= vector_rf_we_in;
      scalar_mem_re_out <= scalar_mem_re_in;
      scalar_mem_we_out <= scalar_mem_we_in;
      vector_mem_re_out <= vector_mem_re_in;
      vector_mem_we_out <= vector_mem_we_in;
      mac_reset_out <= mac_reset_in;
      mov_high_sel_out <= mov_high_sel_in;
      halt_out <= halt_in;
      wb_sel_out <= wb_sel_in;
    end
  end
endmodule

module ex_wb_reg #(
  parameter int PC_WIDTH = 16,
  parameter int INSTR_WIDTH = 32,
  parameter int SCALAR_WIDTH = 16,
  parameter int VECTOR_WIDTH = 512
) (
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    valid_in,
  input  logic [PC_WIDTH-1:0]     pc_in,
  input  logic [INSTR_WIDTH-1:0]  instruction_in,
  input  logic [3:0]              opcode_in,
  input  logic [3:0]              rd_in,
  input  logic [SCALAR_WIDTH-1:0] scalar_wb_data_in,
  input  logic [VECTOR_WIDTH-1:0] vector_wb_data_in,
  input  logic                    scalar_rf_we_in,
  input  logic                    vector_rf_we_in,
  input  logic                    halt_in,
  output logic                    valid_out,
  output logic [PC_WIDTH-1:0]     pc_out,
  output logic [INSTR_WIDTH-1:0]  instruction_out,
  output logic [3:0]              opcode_out,
  output logic [3:0]              rd_out,
  output logic [SCALAR_WIDTH-1:0] scalar_wb_data_out,
  output logic [VECTOR_WIDTH-1:0] vector_wb_data_out,
  output logic                    scalar_rf_we_out,
  output logic                    vector_rf_we_out,
  output logic                    halt_out
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_out <= 1'b0;
      pc_out <= '0;
      instruction_out <= '0;
      opcode_out <= '0;
      rd_out <= '0;
      scalar_wb_data_out <= '0;
      vector_wb_data_out <= '0;
      scalar_rf_we_out <= 1'b0;
      vector_rf_we_out <= 1'b0;
      halt_out <= 1'b0;
    end else begin
      valid_out <= valid_in;
      pc_out <= pc_in;
      instruction_out <= instruction_in;
      opcode_out <= opcode_in;
      rd_out <= rd_in;
      scalar_wb_data_out <= scalar_wb_data_in;
      vector_wb_data_out <= vector_wb_data_in;
      scalar_rf_we_out <= scalar_rf_we_in;
      vector_rf_we_out <= vector_rf_we_in;
      halt_out <= halt_in;
    end
  end
endmodule
