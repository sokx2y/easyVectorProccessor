module imm_gen #(
  parameter int SCALAR_WIDTH = 16
) (
  input  logic [31:0] instruction,
  output logic [SCALAR_WIDTH-1:0] imm5_ext,
  output logic [7:0]              imm8
);
  always_comb begin
    imm5_ext = {{(SCALAR_WIDTH-5){instruction[4]}}, instruction[4:0]};
    imm8     = instruction[15:8];
  end
endmodule
