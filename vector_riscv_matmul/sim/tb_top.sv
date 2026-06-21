`timescale 1ns/1ps

module tb_top;
  localparam int MAX_CYCLES = 500;
  localparam int ACC_WIDTH = 32;
  localparam int VECTOR_WIDTH = 512;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic halted;
  logic [15:0] dbg_pc;
  logic [31:0] dbg_instruction;
  logic dbg_scalar_rf_we, dbg_vector_rf_we;
  logic dbg_scalar_mem_we, dbg_vector_mem_we;
  logic [VECTOR_WIDTH-1:0] expected [0:7];
  integer cycles;
  integer errors;
  integer row;
  integer col;
  logic signed [ACC_WIDTH-1:0] actual_lane;
  logic signed [ACC_WIDTH-1:0] expected_lane;

  top dut(
    .clk, .rst_n,
    .host_icm_we(1'b0), .host_icm_addr('0), .host_icm_wdata('0),
    .host_icm_wstrb('0), .host_icm_rdata(),
    .host_scalar_we(1'b0), .host_scalar_addr('0),
    .host_scalar_wdata('0), .host_scalar_wstrb('0),
    .host_scalar_rdata(), .host_vector_we(1'b0),
    .host_vector_entry('0), .host_vector_lane('0),
    .host_vector_wdata('0), .host_vector_wstrb('0),
    .host_vector_rdata(), .halted, .dbg_pc, .dbg_instruction,
    .dbg_scalar_rf_we, .dbg_vector_rf_we,
    .dbg_scalar_mem_we, .dbg_vector_mem_we
  );

  always #5 clk = ~clk;

  task print_inputs;
    integer r, c;
    begin
      $display("A =");
      for (r = 0; r < 8; r = r + 1) begin
        $write("  ");
        for (c = 0; c < 8; c = c + 1)
          $write("%0d ", $signed(dut.u_scalar_dcm.mem[r*8+c]));
        $display("");
      end
      $display("B =");
      for (r = 0; r < 8; r = r + 1) begin
        $write("  ");
        for (c = 0; c < 8; c = c + 1)
          $write("%0d ", $signed(dut.u_vector_dcm.mem[r][c*ACC_WIDTH +: ACC_WIDTH]));
        $display("");
      end
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
    $readmemh("expected_output.mem", expected);
    repeat (3) @(posedge clk);
    rst_n <= 1'b1;

    cycles = 0;
    while (!halted && cycles < MAX_CYCLES) begin
      @(posedge clk);
      #1;
      cycles = cycles + 1;
    end

    print_inputs();
    errors = 0;
    $display("Hardware C / Golden C:");
    for (row = 0; row < 8; row = row + 1) begin
      for (col = 0; col < 8; col = col + 1) begin
        actual_lane = dut.u_vector_dcm.mem[16+row][col*ACC_WIDTH +: ACC_WIDTH];
        expected_lane = expected[row][col*ACC_WIDTH +: ACC_WIDTH];
        $display("RESULT %0d %0d %0d", row, col, actual_lane);
        if (actual_lane !== expected_lane) begin
          errors = errors + 1;
          $display("MISMATCH row=%0d col=%0d expected=%0d actual=%0d",
                   row, col, expected_lane, actual_lane);
        end
      end
    end

    if (!halted) begin
      errors = errors + 1;
      $display("FAIL: timeout after %0d cycles", cycles);
    end
    if (errors == 0)
      $display("PASS: 8x8 matrix multiplication, cycles=%0d", cycles);
    else
      $display("FAIL: errors=%0d cycles=%0d", errors, cycles);
    $finish;
  end
endmodule
