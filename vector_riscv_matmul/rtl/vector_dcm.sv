module vector_dcm #(
  parameter int VECTOR_WIDTH = 512,
  parameter int ADDR_WIDTH = 16,
  parameter int DEPTH = 256,
  parameter int LANE_WIDTH = 32,
  parameter bit USE_MEM_INIT = 1'b1,
  parameter int HOST_ADDR_WIDTH = $clog2(DEPTH),
  parameter int HOST_LANE_WIDTH = $clog2(VECTOR_WIDTH / LANE_WIDTH)
) (
  input  logic                    clk,
  input  logic                    re,
  input  logic                    we,
  input  logic [ADDR_WIDTH-1:0]   addr,
  input  logic [VECTOR_WIDTH-1:0] wdata,
  output logic [VECTOR_WIDTH-1:0] rdata,
  input  logic                    host_we,
  input  logic [HOST_ADDR_WIDTH-1:0] host_entry,
  input  logic [HOST_LANE_WIDTH-1:0] host_lane,
  input  logic [LANE_WIDTH-1:0]   host_wdata,
  input  logic [LANE_WIDTH/8-1:0] host_wstrb,
  output logic [LANE_WIDTH-1:0]   host_rdata
);
  logic [VECTOR_WIDTH-1:0] mem [0:DEPTH-1];
  integer byte_index;

  generate
    if (USE_MEM_INIT) begin : g_mem_init
      initial $readmemh("vector_init.mem", mem);
    end
  endgenerate

  always_comb begin
    rdata = (re && addr < DEPTH) ? mem[addr] : '0;
    if (host_entry < DEPTH && host_lane < VECTOR_WIDTH/LANE_WIDTH)
      host_rdata = mem[host_entry][host_lane*LANE_WIDTH +: LANE_WIDTH];
    else
      host_rdata = '0;
  end

  always_ff @(posedge clk) begin
    if (host_we && host_entry < DEPTH &&
        host_lane < VECTOR_WIDTH/LANE_WIDTH) begin
      for (byte_index = 0; byte_index < LANE_WIDTH/8; byte_index = byte_index + 1)
        if (host_wstrb[byte_index])
          mem[host_entry][host_lane*LANE_WIDTH + byte_index*8 +: 8] <=
            host_wdata[byte_index*8 +: 8];
    end else if (we && addr < DEPTH) begin
      mem[addr] <= wdata;
    end
  end
endmodule
