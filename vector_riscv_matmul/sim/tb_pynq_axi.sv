`timescale 1ns/1ps

module tb_pynq_axi;
  localparam int PROGRAM_WORDS = 234;
  localparam int N = 8;
  localparam int VECTOR_LANES = 16;
  localparam int ACC_WIDTH = 32;
  localparam int MAX_POLLS = 400;
  localparam logic [1:0] AXI_OKAY = 2'b00;
  localparam logic [1:0] AXI_SLVERR = 2'b10;

  logic s_axi_aclk = 1'b0;
  logic s_axi_aresetn = 1'b0;
  logic [15:0] s_axi_awaddr;
  logic s_axi_awvalid;
  logic s_axi_awready;
  logic [31:0] s_axi_wdata;
  logic [3:0] s_axi_wstrb;
  logic s_axi_wvalid;
  logic s_axi_wready;
  logic [1:0] s_axi_bresp;
  logic s_axi_bvalid;
  logic s_axi_bready;
  logic [15:0] s_axi_araddr;
  logic s_axi_arvalid;
  logic s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic s_axi_rvalid;
  logic s_axi_rready;

  integer errors;
  integer index;
  integer row;
  integer col;
  integer lane;
  integer polls;
  logic [31:0] rd;
  logic [1:0] resp;
  logic [31:0] status;

  pynq_vector_processor_ip dut(
    .s_axi_aclk,
    .s_axi_aresetn,
    .s_axi_awaddr,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_bready,
    .s_axi_araddr,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rvalid,
    .s_axi_rready
  );

  always #5 s_axi_aclk = ~s_axi_aclk;

  function automatic [15:0] vector_word_addr(
    input integer entry,
    input integer lane_index
  );
    vector_word_addr = 16'h4000 + ((entry * 16 + lane_index) * 4);
  endfunction

  task automatic send_aw(input logic [15:0] address);
    begin
      @(negedge s_axi_aclk);
      s_axi_awaddr = address;
      s_axi_awvalid = 1'b1;
      do @(posedge s_axi_aclk); while (!s_axi_awready);
      #1;
      s_axi_awvalid = 1'b0;
    end
  endtask

  task automatic send_w(
    input logic [31:0] data,
    input logic [3:0] strobes
  );
    begin
      @(negedge s_axi_aclk);
      s_axi_wdata = data;
      s_axi_wstrb = strobes;
      s_axi_wvalid = 1'b1;
      do @(posedge s_axi_aclk); while (!s_axi_wready);
      #1;
      s_axi_wvalid = 1'b0;
    end
  endtask

  // order: 0 = same-cycle, 1 = AW first, 2 = W first.
  task automatic axi_write(
    input logic [15:0] address,
    input logic [31:0] data,
    input logic [3:0] strobes,
    input integer order,
    output logic [1:0] response
  );
    begin
      case (order)
        1: begin
          send_aw(address);
          @(posedge s_axi_aclk);
          send_w(data, strobes);
        end
        2: begin
          send_w(data, strobes);
          @(posedge s_axi_aclk);
          send_aw(address);
        end
        default: begin
          fork
            send_aw(address);
            send_w(data, strobes);
          join
        end
      endcase

      while (!s_axi_bvalid)
        @(posedge s_axi_aclk);
      response = s_axi_bresp;
      s_axi_bready = 1'b1;
      @(posedge s_axi_aclk);
      #1;
      s_axi_bready = 1'b0;
    end
  endtask

  task automatic axi_read(
    input logic [15:0] address,
    output logic [31:0] data,
    output logic [1:0] response
  );
    begin
      @(negedge s_axi_aclk);
      s_axi_araddr = address;
      s_axi_arvalid = 1'b1;
      do @(posedge s_axi_aclk); while (!s_axi_arready);
      #1;
      s_axi_arvalid = 1'b0;

      while (!s_axi_rvalid)
        @(posedge s_axi_aclk);
      data = s_axi_rdata;
      response = s_axi_rresp;
      s_axi_rready = 1'b1;
      @(posedge s_axi_aclk);
      #1;
      s_axi_rready = 1'b0;
    end
  endtask

  task automatic expect_resp(
    input logic [1:0] actual,
    input logic [1:0] expected,
    input string operation
  );
    begin
      if (actual !== expected) begin
        errors = errors + 1;
        $display("AXI_RESP_MISMATCH %s expected=%b actual=%b",
                 operation, expected, actual);
      end
    end
  endtask

  task automatic wait_for_done;
    begin
      polls = 0;
      status = '0;
      while (!status[0] && polls < MAX_POLLS) begin
        axi_read(16'h0004, status, resp);
        expect_resp(resp, AXI_OKAY, "STATUS poll");
        polls = polls + 1;
      end
      if (!status[0]) begin
        errors = errors + 1;
        $display("AXI TIMEOUT waiting for DONE");
      end
    end
  endtask

  initial begin : test_sequence
    logic [31:0] program_image [0:PROGRAM_WORDS-1];
    logic [15:0] scalar_image [0:63];
    logic [511:0] vector_image [0:23];
    logic [511:0] expected_image [0:7];

    $dumpfile("dump_axi.vcd");
    // Keep the deployment waveform focused. Recursively dumping the complete
    // core also records large RF/DCM arrays and makes Vivado GUI simulation
    // impractically slow when xelab debug is enabled.
    $dumpvars(0, tb_pynq_axi.dut.u_axi_lite_frontend);
    $dumpvars(1, tb_pynq_axi.dut.u_processor_host_wrapper);
    $readmemh("program.mem", program_image);
    $readmemh("scalar_init.mem", scalar_image);
    $readmemh("vector_init.mem", vector_image);
    $readmemh("expected_output.mem", expected_image);

    s_axi_awaddr = '0;
    s_axi_awvalid = 1'b0;
    s_axi_wdata = '0;
    s_axi_wstrb = '0;
    s_axi_wvalid = 1'b0;
    s_axi_bready = 1'b0;
    s_axi_araddr = '0;
    s_axi_arvalid = 1'b0;
    s_axi_rready = 1'b0;
    errors = 0;

    // Vivado project-mode simulation loads glbl, whose GSR remains asserted
    // for roughly 100 ns. Keep the AXI reset active beyond that interval so
    // GUI and direct xsim runs execute the same transaction sequence.
    repeat (16) @(posedge s_axi_aclk);
    s_axi_aresetn = 1'b1;

    // Read every control/status register.
    axi_read(16'h0000, rd, resp);
    expect_resp(resp, AXI_OKAY, "CONTROL read");
    axi_read(16'h0004, status, resp);
    expect_resp(resp, AXI_OKAY, "STATUS read");
    if (!status[4]) begin
      errors = errors + 1;
      $display("AXI initial state is not IDLE");
    end
    axi_read(16'h0008, rd, resp);
    expect_resp(resp, AXI_OKAY, "CYCLE_COUNT read");
    if (rd !== 0) begin
      errors = errors + 1;
      $display("AXI initial cycle count is not zero");
    end
    axi_read(16'h000c, rd, resp);
    expect_resp(resp, AXI_OKAY, "CURRENT_PC read");
    axi_read(16'h0010, rd, resp);
    expect_resp(resp, AXI_OKAY, "VERSION read");
    if (rd !== 32'h0001_0000) begin
      errors = errors + 1;
      $display("AXI VERSION mismatch");
    end

    // Read-only, illegal, and unaligned accesses must return SLVERR.
    axi_write(16'h0004, 32'h1, 4'b1111, 0, resp);
    expect_resp(resp, AXI_SLVERR, "STATUS write");
    axi_read(16'h3000, rd, resp);
    expect_resp(resp, AXI_SLVERR, "illegal read");
    axi_read(16'h1002, rd, resp);
    expect_resp(resp, AXI_SLVERR, "unaligned read");
    axi_write(16'h0000, 32'h2, 4'b0001, 0, resp);
    expect_resp(resp, AXI_OKAY, "SOFT_RESET");

    // Explicitly cover AW-first, W-first, and simultaneous writes.
    axi_write(16'h1000, program_image[0], 4'b1111, 1, resp);
    expect_resp(resp, AXI_OKAY, "AW-first write");
    axi_write(16'h1004, program_image[1], 4'b1111, 2, resp);
    expect_resp(resp, AXI_OKAY, "W-first write");
    axi_write(16'h1008, program_image[2], 4'b1111, 0, resp);
    expect_resp(resp, AXI_OKAY, "same-cycle write");
    axi_read(16'h1000, rd, resp);
    expect_resp(resp, AXI_OKAY, "AW-first readback");
    if (rd !== program_image[0]) begin
      errors = errors + 1;
      $display("AW-first data mismatch");
    end
    axi_read(16'h1004, rd, resp);
    if (rd !== program_image[1]) begin
      errors = errors + 1;
      $display("W-first data mismatch");
    end
    axi_read(16'h1008, rd, resp);
    if (rd !== program_image[2]) begin
      errors = errors + 1;
      $display("Same-cycle data mismatch");
    end

    // Dynamically load the complete executable and matrices through AXI.
    for (index = 0; index < PROGRAM_WORDS; index = index + 1) begin
      axi_write(16'h1000 + index*4, program_image[index],
                4'b1111, 0, resp);
      expect_resp(resp, AXI_OKAY, "program load");
    end
    for (index = 0; index < 64; index = index + 1) begin
      axi_write(16'h2000 + index*4, {16'b0, scalar_image[index]},
                4'b0011, 0, resp);
      expect_resp(resp, AXI_OKAY, "scalar load");
    end
    for (row = 0; row < N; row = row + 1)
      for (lane = 0; lane < VECTOR_LANES; lane = lane + 1) begin
        axi_write(
          vector_word_addr(row, lane),
          vector_image[row][lane*ACC_WIDTH +: ACC_WIDTH],
          4'b1111, 0, resp
        );
        expect_resp(resp, AXI_OKAY, "vector load");
      end

    axi_write(16'h0000, 32'h1, 4'b0001, 1, resp);
    expect_resp(resp, AXI_OKAY, "START");

    status = '0;
    while (!status[1]) begin
      axi_read(16'h0004, status, resp);
      expect_resp(resp, AXI_OKAY, "wait BUSY");
    end

    // Memory windows are inaccessible while the core is running.
    axi_write(16'h1000, 32'hdead_beef, 4'b1111, 2, resp);
    expect_resp(resp, AXI_SLVERR, "BUSY memory write");
    axi_read(16'h4000, rd, resp);
    expect_resp(resp, AXI_SLVERR, "BUSY memory read");
    axi_write(16'h0000, 32'h1, 4'b0001, 0, resp);
    expect_resp(resp, AXI_SLVERR, "duplicate START");
    axi_read(16'h0004, status, resp);
    expect_resp(resp, AXI_OKAY, "BUSY status");
    if (!status[3]) begin
      errors = errors + 1;
      $display("AXI ACCESS_ERROR did not become sticky");
    end

    wait_for_done();
    axi_read(16'h0008, rd, resp);
    expect_resp(resp, AXI_OKAY, "final CYCLE_COUNT");
    if (rd !== 32'd237) begin
      errors = errors + 1;
      $display("AXI cycle mismatch expected=237 actual=%0d", rd);
    end else
      $display("AXI PIPELINED_CYCLES=%0d", rd);
    axi_read(16'h000c, rd, resp);
    expect_resp(resp, AXI_OKAY, "final CURRENT_PC");

    axi_read(16'h1000, rd, resp);
    expect_resp(resp, AXI_OKAY, "post-run ICM read");
    if (rd !== program_image[0]) begin
      errors = errors + 1;
      $display("Rejected AXI BUSY write modified ICM");
    end

    for (row = 0; row < N; row = row + 1)
      for (col = 0; col < N; col = col + 1) begin
        axi_read(vector_word_addr(16+row, col), rd, resp);
        expect_resp(resp, AXI_OKAY, "result read");
        if (rd !== expected_image[row][col*ACC_WIDTH +: ACC_WIDTH]) begin
          errors = errors + 1;
          $display(
            "AXI_RESULT_MISMATCH row=%0d col=%0d expected=%0d actual=%0d",
            row, col,
            expected_image[row][col*ACC_WIDTH +: ACC_WIDTH], rd
          );
        end
      end

    if (errors == 0)
      $display("PYNQ_AXI PASS");
    else
      $fatal(1, "PYNQ_AXI FAIL errors=%0d", errors);
    $finish;
  end
endmodule
