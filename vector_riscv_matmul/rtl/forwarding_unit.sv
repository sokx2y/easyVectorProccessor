// General EX/WB bypass network. Two instances are used: one before ID/EX is
// captured (WB-to-ID), and one in EX (WB-to-EX).
module forwarding_unit #(
  parameter int SCALAR_WIDTH = 16,
  parameter int VECTOR_WIDTH = 512
) (
  input  logic                    producer_valid,
  input  logic                    producer_scalar_we,
  input  logic                    producer_vector_we,
  input  logic [3:0]              producer_rd,
  input  logic [SCALAR_WIDTH-1:0] producer_scalar_data,
  input  logic [VECTOR_WIDTH-1:0] producer_vector_data,
  input  logic [3:0]              consumer_rs1,
  input  logic [3:0]              consumer_rs2,
  input  logic [3:0]              consumer_rd,
  input  logic [SCALAR_WIDTH-1:0] scalar_a_in,
  input  logic [SCALAR_WIDTH-1:0] scalar_b_in,
  input  logic [SCALAR_WIDTH-1:0] scalar_old_rd_in,
  input  logic [VECTOR_WIDTH-1:0] vector_old_in,
  input  logic [VECTOR_WIDTH-1:0] vector_src_in,
  output logic [SCALAR_WIDTH-1:0] scalar_a_out,
  output logic [SCALAR_WIDTH-1:0] scalar_b_out,
  output logic [SCALAR_WIDTH-1:0] scalar_old_rd_out,
  output logic [VECTOR_WIDTH-1:0] vector_old_out,
  output logic [VECTOR_WIDTH-1:0] vector_src_out,
  output logic                    scalar_forward,
  output logic                    vector_forward
);
  always_comb begin
    scalar_a_out = scalar_a_in;
    scalar_b_out = scalar_b_in;
    scalar_old_rd_out = scalar_old_rd_in;
    vector_old_out = vector_old_in;
    vector_src_out = vector_src_in;
    scalar_forward = 1'b0;
    vector_forward = 1'b0;

    if (producer_valid && producer_scalar_we) begin
      if (producer_rd == consumer_rs1) begin
        scalar_a_out = producer_scalar_data;
        scalar_forward = 1'b1;
      end
      if (producer_rd == consumer_rs2) begin
        scalar_b_out = producer_scalar_data;
        scalar_forward = 1'b1;
      end
      if (producer_rd == consumer_rd) begin
        scalar_old_rd_out = producer_scalar_data;
        scalar_forward = 1'b1;
      end
    end

    if (producer_valid && producer_vector_we) begin
      if (producer_rd == consumer_rd) begin
        vector_old_out = producer_vector_data;
        vector_forward = 1'b1;
      end
      if (producer_rd == consumer_rs2) begin
        vector_src_out = producer_vector_data;
        vector_forward = 1'b1;
      end
    end
  end
endmodule
