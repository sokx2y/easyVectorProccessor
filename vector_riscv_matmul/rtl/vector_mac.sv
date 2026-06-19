module vector_mac #(
  parameter int VEC_LANES = 16,
  parameter int SCALAR_WIDTH = 16,
  parameter int LANE_WIDTH = 8,
  parameter int ACC_WIDTH = 32,
  parameter int VECTOR_WIDTH = VEC_LANES * ACC_WIDTH
) (
  input  logic                              reset_acc,
  input  logic [SCALAR_WIDTH-1:0]           scalar,
  input  logic [SCALAR_WIDTH-1:0]           vl,
  input  logic [VECTOR_WIDTH-1:0]           old_acc,
  input  logic [VECTOR_WIDTH-1:0]           vector_operand,
  output logic [VECTOR_WIDTH-1:0]           result
);
  integer lane;
  logic signed [ACC_WIDTH-1:0] old_lane;
  logic signed [LANE_WIDTH-1:0] weight_lane;
  logic signed [SCALAR_WIDTH-1:0] scalar_s;
  logic signed [(ACC_WIDTH+SCALAR_WIDTH)-1:0] math;

  always_comb begin
    result = old_acc;
    scalar_s = scalar;
    for (lane = 0; lane < VEC_LANES; lane = lane + 1) begin
      old_lane = old_acc[lane*ACC_WIDTH +: ACC_WIDTH];
      weight_lane = vector_operand[lane*ACC_WIDTH +: LANE_WIDTH];
      if (lane < vl) begin
        if (reset_acc)
          result[lane*ACC_WIDTH +: ACC_WIDTH] = '0;
        else begin
          math = old_lane + scalar_s * weight_lane;
          result[lane*ACC_WIDTH +: ACC_WIDTH] = math[ACC_WIDTH-1:0];
        end
      end
    end
  end
endmodule
