module icm #(
  parameter int INSTR_WIDTH = 32,
  parameter int PC_WIDTH = 16,
  parameter int DEPTH = 512
) (
  input  logic [PC_WIDTH-1:0]    addr,
  output logic [INSTR_WIDTH-1:0] instruction
);
  logic [INSTR_WIDTH-1:0] mem [0:DEPTH-1];

  initial $readmemh("program.mem", mem);

  always_comb begin
    if (addr < DEPTH)
      instruction = mem[addr];
    else
      instruction = 32'hf0000000;
  end
endmodule
