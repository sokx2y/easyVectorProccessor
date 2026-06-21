`timescale 1ns/1ps

module tb_processor_host_wrapper;
  localparam int PROGRAM_WORDS = 234;
  localparam int N = 8;
  localparam int VECTOR_LANES = 16;
  localparam int ACC_WIDTH = 32;
  localparam int MAX_POLLS = 400;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic host_valid;
  logic host_write;
  logic [15:0] host_addr;
  logic [31:0] host_wdata;
  logic [3:0] host_wstrb;
  logic host_ready;
  logic [31:0] host_rdata;
  logic host_error;

  logic [31:0] program_image [0:PROGRAM_WORDS-1];
  logic [15:0] scalar_image [0:63];
  logic [511:0] vector_image [0:23];
  logic [511:0] expected_image [0:7];
  integer a2 [0:N-1][0:N-1];
  integer b2 [0:N-1][0:N-1];
  integer golden2 [0:N-1][0:N-1];
  integer errors;
  integer row;
  integer col;
  integer lane;
  integer index;
  integer k;
  integer polls;
  logic [31:0] rd;
  logic err;
  logic [31:0] status;

  processor_host_wrapper dut(
    .clk, .rst_n, .host_valid, .host_write, .host_addr,
    .host_wdata, .host_wstrb, .host_ready, .host_rdata, .host_error
  );

  always #5 clk = ~clk;

  function automatic [15:0] vector_word_addr(
    input integer entry,
    input integer lane_index
  );
    vector_word_addr = 16'h4000 + ((entry * 16 + lane_index) * 4);
  endfunction

  task automatic host_write_word(
    input logic [15:0] address,
    input logic [31:0] data,
    input logic [3:0] strobes,
    output logic transaction_error
  );
    begin
      @(negedge clk);
      host_valid = 1'b1;
      host_write = 1'b1;
      host_addr = address;
      host_wdata = data;
      host_wstrb = strobes;
      #1;
      transaction_error = host_error;
      if (!host_ready) begin
        errors = errors + 1;
        $display("HOST_READY missing for write addr=%04x", address);
      end
      @(posedge clk);
      #1;
      host_valid = 1'b0;
      host_write = 1'b0;
      host_wstrb = '0;
    end
  endtask

  task automatic host_read_word(
    input logic [15:0] address,
    output logic [31:0] data,
    output logic transaction_error
  );
    begin
      @(negedge clk);
      host_valid = 1'b1;
      host_write = 1'b0;
      host_addr = address;
      host_wdata = '0;
      host_wstrb = '0;
      #1;
      data = host_rdata;
      transaction_error = host_error;
      if (!host_ready) begin
        errors = errors + 1;
        $display("HOST_READY missing for read addr=%04x", address);
      end
      @(posedge clk);
      #1;
      host_valid = 1'b0;
    end
  endtask

  task automatic expect_no_error(
    input logic transaction_error,
    input string operation
  );
    begin
      if (transaction_error) begin
        errors = errors + 1;
        $display("UNEXPECTED HOST ERROR: %s", operation);
      end
    end
  endtask

  task automatic wait_for_done;
    begin
      polls = 0;
      status = '0;
      while (!status[0] && polls < MAX_POLLS) begin
        host_read_word(16'h0004, status, err);
        expect_no_error(err, "STATUS poll");
        polls = polls + 1;
      end
      if (!status[0]) begin
        errors = errors + 1;
        $display("TIMEOUT waiting for DONE");
      end
    end
  endtask

  task automatic check_cycle_count(input string run_name);
    begin
      host_read_word(16'h0008, rd, err);
      expect_no_error(err, {run_name, " cycle count read"});
      if (rd !== 32'd237) begin
        errors = errors + 1;
        $display("%s cycle mismatch expected=237 actual=%0d", run_name, rd);
      end else
        $display("%s CYCLES=%0d", run_name, rd);
    end
  endtask

  initial begin
    $readmemh("program.mem", program_image);
    $readmemh("scalar_init.mem", scalar_image);
    $readmemh("vector_init.mem", vector_image);
    $readmemh("expected_output.mem", expected_image);

    host_valid = 1'b0;
    host_write = 1'b0;
    host_addr = '0;
    host_wdata = '0;
    host_wstrb = '0;
    errors = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    host_read_word(16'h0010, rd, err);
    expect_no_error(err, "VERSION read");
    if (rd !== 32'h0001_0000) begin
      errors = errors + 1;
      $display("VERSION mismatch actual=%08x", rd);
    end

    host_read_word(16'h0004, status, err);
    expect_no_error(err, "initial STATUS");
    if (!status[4] || status[1:0] != 2'b00) begin
      errors = errors + 1;
      $display("Initial state is not IDLE status=%08x", status);
    end

    // Illegal address sets ACCESS_ERROR; SOFT_RESET clears it.
    host_read_word(16'h3000, rd, err);
    if (!err) begin
      errors = errors + 1;
      $display("Illegal address did not report HOST error");
    end
    host_read_word(16'h0004, status, err);
    if (!status[3]) begin
      errors = errors + 1;
      $display("ACCESS_ERROR did not become sticky");
    end
    host_write_word(16'h0000, 32'h0000_0002, 4'b0001, err);
    expect_no_error(err, "initial SOFT_RESET");
    host_read_word(16'h0004, status, err);
    if (status[3] || !status[4]) begin
      errors = errors + 1;
      $display("SOFT_RESET did not clear status=%08x", status);
    end

    // First run: dynamically load the existing program and matrices.
    for (index = 0; index < PROGRAM_WORDS; index = index + 1) begin
      host_write_word(16'h1000 + index*4, program_image[index],
                      4'b1111, err);
      expect_no_error(err, "program load");
    end
    for (index = 0; index < 64; index = index + 1) begin
      host_write_word(16'h2000 + index*4, {16'b0, scalar_image[index]},
                      4'b0011, err);
      expect_no_error(err, "scalar load");
    end
    for (row = 0; row < N; row = row + 1) begin
      for (lane = 0; lane < VECTOR_LANES; lane = lane + 1) begin
        host_write_word(
          vector_word_addr(row, lane),
          vector_image[row][lane*ACC_WIDTH +: ACC_WIDTH],
          4'b1111, err
        );
        expect_no_error(err, "vector load");
      end
    end

    host_read_word(16'h1000, rd, err);
    expect_no_error(err, "ICM readback");
    if (rd !== program_image[0]) begin
      errors = errors + 1;
      $display("ICM readback mismatch");
    end
    host_read_word(16'h20fc, rd, err);
    expect_no_error(err, "Scalar readback");
    if (rd[15:0] !== scalar_image[63]) begin
      errors = errors + 1;
      $display("Scalar readback mismatch");
    end
    host_read_word(vector_word_addr(7, 7), rd, err);
    expect_no_error(err, "Vector readback");
    if (rd !== vector_image[7][7*ACC_WIDTH +: ACC_WIDTH]) begin
      errors = errors + 1;
      $display("Vector readback mismatch");
    end

    host_write_word(16'h0000, 32'h0000_0001, 4'b0001, err);
    expect_no_error(err, "first START");

    // Wait until RUN, then prove memory and duplicate START are rejected.
    status = '0;
    while (!status[1]) begin
      host_read_word(16'h0004, status, err);
      expect_no_error(err, "wait BUSY");
    end
    host_write_word(16'h1000, 32'hdead_beef, 4'b1111, err);
    if (!err) begin
      errors = errors + 1;
      $display("Memory write while BUSY was not rejected");
    end
    host_write_word(16'h0000, 32'h0000_0001, 4'b0001, err);
    if (!err) begin
      errors = errors + 1;
      $display("Duplicate START while BUSY was not rejected");
    end
    host_read_word(16'h0004, status, err);
    if (!status[3]) begin
      errors = errors + 1;
      $display("BUSY rejection did not set ACCESS_ERROR");
    end

    wait_for_done();
    if (!status[2] || status[1]) begin
      errors = errors + 1;
      $display("First run final STATUS invalid=%08x", status);
    end
    check_cycle_count("first run");

    host_read_word(16'h1000, rd, err);
    expect_no_error(err, "post-run ICM read");
    if (rd !== program_image[0]) begin
      errors = errors + 1;
      $display("Rejected BUSY write modified ICM");
    end

    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        host_read_word(vector_word_addr(16+row, col), rd, err);
        expect_no_error(err, "first result read");
        if (rd !== expected_image[row][col*ACC_WIDTH +: ACC_WIDTH]) begin
          errors = errors + 1;
          $display(
            "FIRST_RUN_MISMATCH row=%0d col=%0d expected=%0d actual=%0d",
            row, col,
            expected_image[row][col*ACC_WIDTH +: ACC_WIDTH], rd
          );
        end
      end
    end

    // Second run: keep the same program, replace both A and B at runtime.
    host_write_word(16'h0000, 32'h0000_0002, 4'b0001, err);
    expect_no_error(err, "second-run SOFT_RESET");
    host_read_word(16'h0004, status, err);
    if (!status[4] || status[3]) begin
      errors = errors + 1;
      $display("Second-run reset status invalid=%08x", status);
    end

    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        a2[row][col] = ((row*2 + col*3) % 5) + 1;
        b2[row][col] = ((row*4 + col*2) % 7) + 1;
      end
    end
    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        golden2[row][col] = 0;
        for (k = 0; k < N; k = k + 1)
          golden2[row][col] =
            golden2[row][col] + a2[row][k] * b2[k][col];
      end
    end

    for (row = 0; row < N; row = row + 1)
      for (col = 0; col < N; col = col + 1) begin
        host_write_word(16'h2000 + (row*N+col)*4,
                        a2[row][col], 4'b0011, err);
        expect_no_error(err, "second scalar load");
      end

    for (row = 0; row < N; row = row + 1)
      for (lane = 0; lane < VECTOR_LANES; lane = lane + 1) begin
        if (lane < N)
          host_write_word(vector_word_addr(row, lane),
                          b2[row][lane], 4'b1111, err);
        else
          host_write_word(vector_word_addr(row, lane),
                          32'b0, 4'b1111, err);
        expect_no_error(err, "second vector load");
      end

    host_write_word(16'h0000, 32'h0000_0001, 4'b0001, err);
    expect_no_error(err, "second START");
    wait_for_done();
    check_cycle_count("second run");

    for (row = 0; row < N; row = row + 1)
      for (col = 0; col < N; col = col + 1) begin
        host_read_word(vector_word_addr(16+row, col), rd, err);
        expect_no_error(err, "second result read");
        if ($signed(rd) !== golden2[row][col]) begin
          errors = errors + 1;
          $display(
            "SECOND_RUN_MISMATCH row=%0d col=%0d expected=%0d actual=%0d",
            row, col, golden2[row][col], $signed(rd)
          );
        end
      end

    if (errors == 0)
      $display("PROCESSOR_HOST_WRAPPER PASS");
    else
      $fatal(1, "PROCESSOR_HOST_WRAPPER FAIL errors=%0d", errors);
    $finish;
  end
endmodule
