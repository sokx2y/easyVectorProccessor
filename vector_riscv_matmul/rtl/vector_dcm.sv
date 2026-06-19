module vector_dcm #(
  parameter int VECTOR_WIDTH = 512,
  parameter int ADDR_WIDTH = 16,
  parameter int DEPTH = 256
) (
  input  logic                    clk,
  input  logic                    re,
  input  logic                    we,
  input  logic [ADDR_WIDTH-1:0]   addr,
  input  logic [VECTOR_WIDTH-1:0] wdata,
  output logic [VECTOR_WIDTH-1:0] rdata
);
  logic [VECTOR_WIDTH-1:0] mem [0:DEPTH-1];

  initial $readmemh("vector_init.mem", mem);

  always_comb
    rdata = (re && addr < DEPTH) ? mem[addr] : '0;

  always_ff @(posedge clk)
    if (we && addr < DEPTH)
      mem[addr] <= wdata;
endmodule
