module icm #(
  parameter int INSTR_WIDTH = 32,
  parameter int PC_WIDTH = 16,
  parameter int DEPTH = 512,
  parameter bit USE_MEM_INIT = 1'b1,
  parameter int HOST_ADDR_WIDTH = $clog2(DEPTH)
) (
  input  logic                         clk,
  input  logic [PC_WIDTH-1:0]    addr,
  output logic [INSTR_WIDTH-1:0] instruction,
  input  logic                         host_we,
  input  logic [HOST_ADDR_WIDTH-1:0]   host_addr,
  input  logic [INSTR_WIDTH-1:0]       host_wdata,
  input  logic [INSTR_WIDTH/8-1:0]     host_wstrb,
  output logic [INSTR_WIDTH-1:0]       host_rdata
);
  logic [INSTR_WIDTH-1:0] mem [0:DEPTH-1];
  integer byte_index;

  generate
    if (USE_MEM_INIT) begin : g_mem_init
      initial $readmemh("program.mem", mem);
    end
  endgenerate

  always_comb begin
    if (addr < DEPTH)
      instruction = mem[addr];
    else
      instruction = 32'hf0000000;

    if (host_addr < DEPTH)
      host_rdata = mem[host_addr];
    else
      host_rdata = '0;
  end

  always_ff @(posedge clk) begin
    if (host_we && host_addr < DEPTH) begin
      for (byte_index = 0; byte_index < INSTR_WIDTH/8; byte_index = byte_index + 1)
        if (host_wstrb[byte_index])
          mem[host_addr][byte_index*8 +: 8] <=
            host_wdata[byte_index*8 +: 8];
    end
  end
endmodule
