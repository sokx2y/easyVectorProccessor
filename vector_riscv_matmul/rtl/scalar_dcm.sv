module scalar_dcm #(
  parameter int WIDTH = 16,
  parameter int ADDR_WIDTH = 16,
  parameter int DEPTH = 256,
  parameter bit USE_MEM_INIT = 1'b1,
  parameter int HOST_ADDR_WIDTH = $clog2(DEPTH)
) (
  input  logic                  clk,
  input  logic                  re,
  input  logic                  we,
  input  logic [ADDR_WIDTH-1:0] addr,
  input  logic [WIDTH-1:0]      wdata,
  output logic [WIDTH-1:0]      rdata,
  input  logic                  host_we,
  input  logic [HOST_ADDR_WIDTH-1:0] host_addr,
  input  logic [31:0]           host_wdata,
  input  logic [3:0]            host_wstrb,
  output logic [31:0]           host_rdata
);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  integer byte_index;

  generate
    if (USE_MEM_INIT) begin : g_mem_init
      initial $readmemh("scalar_init.mem", mem);
    end
  endgenerate

  always_comb begin
    rdata = (re && addr < DEPTH) ? mem[addr] : '0;
    host_rdata = (host_addr < DEPTH) ?
      {{(32-WIDTH){1'b0}}, mem[host_addr]} : '0;
  end

  always_ff @(posedge clk) begin
    if (host_we && host_addr < DEPTH) begin
      for (byte_index = 0; byte_index < WIDTH/8; byte_index = byte_index + 1)
        if (host_wstrb[byte_index])
          mem[host_addr][byte_index*8 +: 8] <=
            host_wdata[byte_index*8 +: 8];
    end else if (we && addr < DEPTH) begin
      mem[addr] <= wdata;
    end
  end
endmodule
