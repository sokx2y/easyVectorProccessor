`timescale 1ns/1ps

module tb_memory_host;
  localparam int VECTOR_WIDTH = 512;
  localparam int ACC_WIDTH = 32;

  logic clk = 1'b0;
  integer errors = 0;

  logic [15:0] icm_cpu_addr;
  logic [31:0] icm_instruction;
  logic icm_host_we;
  logic [8:0] icm_host_addr;
  logic [31:0] icm_host_wdata;
  logic [3:0] icm_host_wstrb;
  logic [31:0] icm_host_rdata;

  logic scalar_re, scalar_we;
  logic [15:0] scalar_cpu_addr;
  logic [15:0] scalar_cpu_wdata;
  logic [15:0] scalar_cpu_rdata;
  logic scalar_host_we;
  logic [7:0] scalar_host_addr;
  logic [31:0] scalar_host_wdata;
  logic [3:0] scalar_host_wstrb;
  logic [31:0] scalar_host_rdata;

  logic vector_re, vector_we;
  logic [15:0] vector_cpu_addr;
  logic [VECTOR_WIDTH-1:0] vector_cpu_wdata;
  logic [VECTOR_WIDTH-1:0] vector_cpu_rdata;
  logic vector_host_we;
  logic [7:0] vector_host_entry;
  logic [3:0] vector_host_lane;
  logic [31:0] vector_host_wdata;
  logic [3:0] vector_host_wstrb;
  logic [31:0] vector_host_rdata;

  icm #(.USE_MEM_INIT(1'b0)) u_icm(
    .clk, .addr(icm_cpu_addr), .instruction(icm_instruction),
    .host_we(icm_host_we), .host_addr(icm_host_addr),
    .host_wdata(icm_host_wdata), .host_wstrb(icm_host_wstrb),
    .host_rdata(icm_host_rdata)
  );

  scalar_dcm #(.USE_MEM_INIT(1'b0)) u_scalar_dcm(
    .clk, .re(scalar_re), .we(scalar_we), .addr(scalar_cpu_addr),
    .wdata(scalar_cpu_wdata), .rdata(scalar_cpu_rdata),
    .host_we(scalar_host_we), .host_addr(scalar_host_addr),
    .host_wdata(scalar_host_wdata), .host_wstrb(scalar_host_wstrb),
    .host_rdata(scalar_host_rdata)
  );

  vector_dcm #(.USE_MEM_INIT(1'b0)) u_vector_dcm(
    .clk, .re(vector_re), .we(vector_we), .addr(vector_cpu_addr),
    .wdata(vector_cpu_wdata), .rdata(vector_cpu_rdata),
    .host_we(vector_host_we), .host_entry(vector_host_entry),
    .host_lane(vector_host_lane), .host_wdata(vector_host_wdata),
    .host_wstrb(vector_host_wstrb), .host_rdata(vector_host_rdata)
  );

  always #5 clk = ~clk;

  task check32(input logic [31:0] actual,
               input logic [31:0] expected,
               input string name);
    begin
      if (actual !== expected) begin
        errors = errors + 1;
        $display("MISMATCH %s expected=%08x actual=%08x",
                 name, expected, actual);
      end
    end
  endtask

  initial begin
    icm_cpu_addr = '0;
    icm_host_we = 1'b0;
    icm_host_addr = '0;
    icm_host_wdata = '0;
    icm_host_wstrb = '0;

    scalar_re = 1'b0;
    scalar_we = 1'b0;
    scalar_cpu_addr = '0;
    scalar_cpu_wdata = '0;
    scalar_host_we = 1'b0;
    scalar_host_addr = '0;
    scalar_host_wdata = '0;
    scalar_host_wstrb = '0;

    vector_re = 1'b0;
    vector_we = 1'b0;
    vector_cpu_addr = '0;
    vector_cpu_wdata = '0;
    vector_host_we = 1'b0;
    vector_host_entry = '0;
    vector_host_lane = '0;
    vector_host_wdata = '0;
    vector_host_wstrb = '0;

    // ICM full-word and byte-strobe writes.
    @(negedge clk);
    icm_host_addr = 9'd7;
    icm_host_wdata = 32'h11223344;
    icm_host_wstrb = 4'b1111;
    icm_host_we = 1'b1;
    @(posedge clk);
    #1;
    icm_host_we = 1'b0;
    check32(icm_host_rdata, 32'h11223344, "ICM full host write");
    icm_cpu_addr = 16'd7;
    #1;
    check32(icm_instruction, 32'h11223344, "ICM CPU fetch");

    @(negedge clk);
    icm_host_wdata = 32'haabbccdd;
    icm_host_wstrb = 4'b0101;
    icm_host_we = 1'b1;
    @(posedge clk);
    #1;
    icm_host_we = 1'b0;
    check32(icm_host_rdata, 32'h11bb33dd, "ICM byte strobe");

    // Scalar DCM exposes the 16-bit word in the low half of a 32-bit host word.
    @(negedge clk);
    scalar_host_addr = 8'd9;
    scalar_host_wdata = 32'hdead3344;
    scalar_host_wstrb = 4'b1111;
    scalar_host_we = 1'b1;
    @(posedge clk);
    #1;
    scalar_host_we = 1'b0;
    check32(scalar_host_rdata, 32'h00003344, "Scalar low 16-bit mapping");

    @(negedge clk);
    scalar_host_wdata = 32'h000000dd;
    scalar_host_wstrb = 4'b0001;
    scalar_host_we = 1'b1;
    @(posedge clk);
    #1;
    scalar_host_we = 1'b0;
    check32(scalar_host_rdata, 32'h000033dd, "Scalar byte strobe");
    scalar_cpu_addr = 16'd9;
    scalar_re = 1'b1;
    #1;
    check32({16'b0, scalar_cpu_rdata}, 32'h000033dd, "Scalar CPU read");

    // CPU write is visible through the host read port.
    @(negedge clk);
    scalar_cpu_addr = 16'd10;
    scalar_cpu_wdata = 16'h55aa;
    scalar_we = 1'b1;
    @(posedge clk);
    #1;
    scalar_we = 1'b0;
    scalar_host_addr = 8'd10;
    #1;
    check32(scalar_host_rdata, 32'h000055aa, "Scalar CPU write host read");

    // Host wins a same-cycle conflict.
    @(negedge clk);
    scalar_cpu_addr = 16'd10;
    scalar_cpu_wdata = 16'hffff;
    scalar_we = 1'b1;
    scalar_host_addr = 8'd10;
    scalar_host_wdata = 32'h00001234;
    scalar_host_wstrb = 4'b0011;
    scalar_host_we = 1'b1;
    @(posedge clk);
    #1;
    scalar_we = 1'b0;
    scalar_host_we = 1'b0;
    check32(scalar_host_rdata, 32'h00001234, "Scalar host priority");

    // Vector host writes address individual 32-bit lanes.
    @(negedge clk);
    vector_host_entry = 8'd3;
    vector_host_lane = 4'd2;
    vector_host_wdata = 32'h01020304;
    vector_host_wstrb = 4'b1111;
    vector_host_we = 1'b1;
    @(posedge clk);
    #1;
    vector_host_we = 1'b0;
    check32(vector_host_rdata, 32'h01020304, "Vector lane write");

    @(negedge clk);
    vector_host_lane = 4'd5;
    vector_host_wdata = 32'ha0b0c0d0;
    vector_host_wstrb = 4'b1111;
    vector_host_we = 1'b1;
    @(posedge clk);
    #1;
    vector_host_we = 1'b0;
    check32(vector_host_rdata, 32'ha0b0c0d0, "Vector second lane");
    vector_host_lane = 4'd2;
    #1;
    check32(vector_host_rdata, 32'h01020304, "Vector lane preservation");

    @(negedge clk);
    vector_host_wdata = 32'hffeeddcc;
    vector_host_wstrb = 4'b0101;
    vector_host_we = 1'b1;
    @(posedge clk);
    #1;
    vector_host_we = 1'b0;
    check32(vector_host_rdata, 32'h01ee03cc, "Vector byte strobe");

    // Model a CPU VSTORE: whole-vector CPU write, then host lane readback.
    vector_cpu_wdata = '0;
    vector_cpu_wdata[0*ACC_WIDTH +: ACC_WIDTH] = 32'd149;
    vector_cpu_wdata[7*ACC_WIDTH +: ACC_WIDTH] = 32'd128;
    @(negedge clk);
    vector_cpu_addr = 16'd16;
    vector_we = 1'b1;
    @(posedge clk);
    #1;
    vector_we = 1'b0;
    vector_host_entry = 8'd16;
    vector_host_lane = 4'd0;
    #1;
    check32(vector_host_rdata, 32'd149, "CPU VSTORE lane 0 host read");
    vector_host_lane = 4'd7;
    #1;
    check32(vector_host_rdata, 32'd128, "CPU VSTORE lane 7 host read");

    // Host lane write has priority over a simultaneous CPU whole-vector write.
    @(negedge clk);
    vector_cpu_addr = 16'd16;
    vector_cpu_wdata = {VECTOR_WIDTH{1'b1}};
    vector_we = 1'b1;
    vector_host_entry = 8'd16;
    vector_host_lane = 4'd0;
    vector_host_wdata = 32'hcafebabe;
    vector_host_wstrb = 4'b1111;
    vector_host_we = 1'b1;
    @(posedge clk);
    #1;
    vector_we = 1'b0;
    vector_host_we = 1'b0;
    check32(vector_host_rdata, 32'hcafebabe, "Vector host priority");
    vector_host_lane = 4'd7;
    #1;
    check32(vector_host_rdata, 32'd128,
            "Vector host priority preserves other lanes");

    if (errors == 0)
      $display("MEMORY_HOST PASS");
    else
      $fatal(1, "MEMORY_HOST FAIL errors=%0d", errors);
    $finish;
  end
endmodule
