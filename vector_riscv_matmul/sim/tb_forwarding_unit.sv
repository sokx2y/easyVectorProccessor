`timescale 1ns/1ps

module tb_forwarding_unit;
  localparam int SW = 16;
  localparam int VW = 512;

  logic producer_valid, producer_scalar_we, producer_vector_we;
  logic [3:0] producer_rd;
  logic [SW-1:0] producer_scalar_data;
  logic [VW-1:0] producer_vector_data;
  logic [3:0] consumer_rs1, consumer_rs2, consumer_rd;
  logic [SW-1:0] scalar_a_in, scalar_b_in, scalar_old_rd_in;
  logic [VW-1:0] vector_old_in, vector_src_in;
  logic [SW-1:0] scalar_a_out, scalar_b_out, scalar_old_rd_out;
  logic [VW-1:0] vector_old_out, vector_src_out;
  logic scalar_forward, vector_forward;

  forwarding_unit dut(
    .producer_valid, .producer_scalar_we, .producer_vector_we,
    .producer_rd, .producer_scalar_data, .producer_vector_data,
    .consumer_rs1, .consumer_rs2, .consumer_rd,
    .scalar_a_in, .scalar_b_in, .scalar_old_rd_in,
    .vector_old_in, .vector_src_in,
    .scalar_a_out, .scalar_b_out, .scalar_old_rd_out,
    .vector_old_out, .vector_src_out,
    .scalar_forward, .vector_forward
  );

  initial begin
    producer_valid = 1'b1;
    producer_scalar_we = 1'b0;
    producer_vector_we = 1'b1;
    producer_rd = 4'd6;
    producer_scalar_data = 16'h1234;
    producer_vector_data = {VW{1'b1}};
    consumer_rs1 = 4'd0;
    consumer_rs2 = 4'd5;
    consumer_rd = 4'd6;
    scalar_a_in = '0;
    scalar_b_in = '0;
    scalar_old_rd_in = '0;
    vector_old_in = '0;
    vector_src_in = '0;
    #1;
    if (!vector_forward || vector_old_out !== producer_vector_data)
      $fatal(1, "FAIL: consecutive VMAC accumulator forwarding");

    producer_rd = 4'd5;
    consumer_rd = 4'd6;
    consumer_rs2 = 4'd5;
    #1;
    if (!vector_forward || vector_src_out !== producer_vector_data)
      $fatal(1, "FAIL: VLOAD-to-VMAC source forwarding");

    producer_vector_we = 1'b0;
    producer_scalar_we = 1'b1;
    producer_rd = 4'd3;
    consumer_rs1 = 4'd3;
    #1;
    if (!scalar_forward || scalar_a_out !== producer_scalar_data)
      $fatal(1, "FAIL: scalar LOAD-to-consumer forwarding");

    $display("FORWARDING_UNIT PASS");
    $finish;
  end
endmodule
