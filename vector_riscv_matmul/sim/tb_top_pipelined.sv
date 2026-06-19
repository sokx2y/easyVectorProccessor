`timescale 1ns/1ps

module tb_top_pipelined;
  localparam int MAX_CYCLES = 600;
  localparam int ACC_WIDTH = 32;
  localparam int VECTOR_WIDTH = 512;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic baseline_halted, pipeline_halted;
  logic [15:0] baseline_pc;
  logic [31:0] baseline_instruction;
  logic baseline_scalar_rf_we, baseline_vector_rf_we;
  logic baseline_scalar_mem_we, baseline_vector_mem_we;

  logic [15:0] pipeline_pc;
  logic if_id_valid, id_ex_valid, ex_wb_valid;
  logic [31:0] if_id_instruction;
  logic [3:0] id_ex_opcode, ex_wb_opcode;
  logic pipeline_scalar_rf_we, pipeline_vector_rf_we;
  logic scalar_forward, vector_forward, stall, bubble;
  logic [VECTOR_WIDTH-1:0] vload_data;
  logic [VECTOR_WIDTH-1:0] vmac_operand_before;
  logic [VECTOR_WIDTH-1:0] vmac_operand_after;
  logic [VECTOR_WIDTH-1:0] vmac_output;

  logic [VECTOR_WIDTH-1:0] expected [0:7];
  integer elapsed_cycles;
  integer baseline_cycles;
  integer pipeline_cycles;
  integer baseline_errors;
  integer pipeline_errors;
  integer vload_to_vmac_forward_count;
  integer scalar_forward_count;
  integer accumulator_forward_count;
  integer vmac_to_vstore_forward_count;
  integer row;
  integer col;
  logic signed [ACC_WIDTH-1:0] baseline_lane;
  logic signed [ACC_WIDTH-1:0] pipeline_lane;
  logic signed [ACC_WIDTH-1:0] expected_lane;

  top dut_baseline(
    .clk, .rst_n, .halted(baseline_halted), .dbg_pc(baseline_pc),
    .dbg_instruction(baseline_instruction),
    .dbg_scalar_rf_we(baseline_scalar_rf_we),
    .dbg_vector_rf_we(baseline_vector_rf_we),
    .dbg_scalar_mem_we(baseline_scalar_mem_we),
    .dbg_vector_mem_we(baseline_vector_mem_we)
  );

  top_pipelined dut_pipeline(
    .clk, .rst_n, .halted(pipeline_halted), .dbg_pc(pipeline_pc),
    .dbg_if_id_valid(if_id_valid),
    .dbg_if_id_instruction(if_id_instruction),
    .dbg_id_ex_valid(id_ex_valid), .dbg_id_ex_opcode(id_ex_opcode),
    .dbg_ex_wb_valid(ex_wb_valid), .dbg_ex_wb_opcode(ex_wb_opcode),
    .dbg_scalar_rf_we(pipeline_scalar_rf_we),
    .dbg_vector_rf_we(pipeline_vector_rf_we),
    .dbg_scalar_forward(scalar_forward),
    .dbg_vector_forward(vector_forward), .dbg_vload_data(vload_data),
    .dbg_vmac_operand_before(vmac_operand_before),
    .dbg_vmac_operand_after(vmac_operand_after),
    .dbg_vmac_output(vmac_output), .dbg_stall(stall),
    .dbg_bubble(bubble)
  );

  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (!rst_n) begin
      vload_to_vmac_forward_count <= 0;
      scalar_forward_count <= 0;
      accumulator_forward_count <= 0;
      vmac_to_vstore_forward_count <= 0;
    end else begin
      if (dut_pipeline.ex_vector_forward &&
          dut_pipeline.id_ex_opcode == 4'h7 &&
          dut_pipeline.ex_wb_opcode == 4'h5)
        vload_to_vmac_forward_count <= vload_to_vmac_forward_count + 1;
      if (dut_pipeline.ex_scalar_forward ||
          dut_pipeline.id_scalar_forward)
        scalar_forward_count <= scalar_forward_count + 1;
      if ((dut_pipeline.ex_vector_forward &&
           dut_pipeline.id_ex_opcode == 4'h7 &&
           dut_pipeline.ex_wb_opcode == 4'h7) ||
          (dut_pipeline.id_vector_forward &&
           dut_pipeline.id_opcode == 4'h7 &&
           dut_pipeline.ex_wb_opcode == 4'h7))
        accumulator_forward_count <= accumulator_forward_count + 1;
      if ((dut_pipeline.ex_vector_forward &&
           dut_pipeline.id_ex_opcode == 4'h6 &&
           dut_pipeline.ex_wb_opcode == 4'h7) ||
          (dut_pipeline.id_vector_forward &&
           dut_pipeline.id_opcode == 4'h6 &&
           dut_pipeline.ex_wb_opcode == 4'h7))
        vmac_to_vstore_forward_count <= vmac_to_vstore_forward_count + 1;
    end
  end

  initial begin
    $dumpfile("dump_pipeline.vcd");
    $dumpvars(0, tb_top_pipelined);
    $readmemh("expected_output.mem", expected);

    repeat (3) @(posedge clk);
    rst_n <= 1'b1;

    elapsed_cycles = 0;
    baseline_cycles = -1;
    pipeline_cycles = -1;
    vload_to_vmac_forward_count = 0;
    scalar_forward_count = 0;
    accumulator_forward_count = 0;
    vmac_to_vstore_forward_count = 0;
    while ((baseline_cycles < 0 || pipeline_cycles < 0) &&
           elapsed_cycles < MAX_CYCLES) begin
      @(posedge clk);
      #1;
      elapsed_cycles = elapsed_cycles + 1;
      if (baseline_halted && baseline_cycles < 0)
        baseline_cycles = elapsed_cycles;
      if (pipeline_halted && pipeline_cycles < 0)
        pipeline_cycles = elapsed_cycles;
    end

    baseline_errors = 0;
    pipeline_errors = 0;
    for (row = 0; row < 8; row = row + 1) begin
      for (col = 0; col < 8; col = col + 1) begin
        expected_lane =
          expected[row][col*ACC_WIDTH +: ACC_WIDTH];
        baseline_lane =
          dut_baseline.u_vector_dcm.mem[16+row][col*ACC_WIDTH +: ACC_WIDTH];
        pipeline_lane =
          dut_pipeline.u_vector_dcm.mem[16+row][col*ACC_WIDTH +: ACC_WIDTH];

        $display("PIPE_RESULT %0d %0d %0d", row, col, pipeline_lane);
        if (baseline_lane !== expected_lane) begin
          baseline_errors = baseline_errors + 1;
          $display("BASELINE_MISMATCH row=%0d col=%0d expected=%0d actual=%0d",
                   row, col, expected_lane, baseline_lane);
        end
        if (pipeline_lane !== expected_lane) begin
          pipeline_errors = pipeline_errors + 1;
          $display("PIPELINE_MISMATCH row=%0d col=%0d expected=%0d actual=%0d",
                   row, col, expected_lane, pipeline_lane);
        end
      end
    end

    if (baseline_cycles < 0)
      baseline_errors = baseline_errors + 1;
    if (pipeline_cycles < 0)
      pipeline_errors = pipeline_errors + 1;
    if (vload_to_vmac_forward_count == 0) begin
      pipeline_errors = pipeline_errors + 1;
      $display("PIPELINE_MISMATCH: VLOAD-to-VMAC forwarding never activated");
    end
    if (vmac_to_vstore_forward_count == 0) begin
      pipeline_errors = pipeline_errors + 1;
      $display("PIPELINE_MISMATCH: VMAC-to-VSTORE forwarding never activated");
    end

    $display("BASELINE_CYCLES=%0d", baseline_cycles);
    $display("PIPELINED_CYCLES=%0d", pipeline_cycles);
    $display("VLOAD_TO_VMAC_FORWARD_COUNT=%0d",
             vload_to_vmac_forward_count);
    $display("SCALAR_FORWARD_COUNT=%0d", scalar_forward_count);
    $display("ACCUMULATOR_FORWARD_COUNT=%0d",
             accumulator_forward_count);
    $display("VMAC_TO_VSTORE_FORWARD_COUNT=%0d",
             vmac_to_vstore_forward_count);
    if (baseline_errors == 0)
      $display("BASELINE PASS");
    else
      $display("BASELINE FAIL errors=%0d", baseline_errors);
    if (pipeline_errors == 0)
      $display("PIPELINED PASS");
    else
      $display("PIPELINED FAIL errors=%0d", pipeline_errors);

    $finish;
  end
endmodule
