module pc #(
  parameter int PC_WIDTH = 16
) (
  input  logic                clk,
  input  logic                rst_n,
  input  logic                enable,
  output logic [PC_WIDTH-1:0] value
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      value <= '0;
    else if (enable)
      value <= value + 1'b1;
  end
endmodule
