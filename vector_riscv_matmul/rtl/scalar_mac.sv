module scalar_mac #(
  parameter int WIDTH = 16
) (
  input  logic                    reset_acc,
  input  logic signed [WIDTH-1:0] old_acc,
  input  logic signed [WIDTH-1:0] operand_a,
  input  logic signed [WIDTH-1:0] operand_b,
  output logic signed [WIDTH-1:0] result
);
  logic signed [(2*WIDTH)-1:0] wide_result;

  always_comb begin
    wide_result = reset_acc ? '0 : old_acc + operand_a * operand_b;
    result = wide_result[WIDTH-1:0];
  end
endmodule
