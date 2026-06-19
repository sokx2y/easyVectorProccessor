module scalar_rf #(
  parameter int WIDTH = 16,
  parameter int NUM_REGS = 16
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic [3:0]       raddr1,
  input  logic [3:0]       raddr2,
  input  logic [3:0]       raddr_rd,
  input  logic [3:0]       waddr,
  input  logic             we,
  input  logic [WIDTH-1:0] wdata,
  output logic [WIDTH-1:0] rdata1,
  output logic [WIDTH-1:0] rdata2,
  output logic [WIDTH-1:0] rdata_rd,
  output logic [WIDTH-1:0] vconfig
);
  logic [WIDTH-1:0] regs [0:NUM_REGS-1];
  integer i;

  always_comb begin
    rdata1 = regs[raddr1];
    rdata2 = regs[raddr2];
    rdata_rd = regs[raddr_rd];
    vconfig = regs[15];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < NUM_REGS; i = i + 1)
        regs[i] <= '0;
    end else if (we) begin
      regs[waddr] <= wdata;
    end
  end
endmodule
