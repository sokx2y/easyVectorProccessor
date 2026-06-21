module pynq_vector_processor_ip #(
  parameter int C_S_AXI_ADDR_WIDTH = 16,
  parameter int C_S_AXI_DATA_WIDTH = 32
) (
  input  logic                          s_axi_aclk,
  input  logic                          s_axi_aresetn,
  input  logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
  input  logic                          s_axi_awvalid,
  output logic                          s_axi_awready,
  input  logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
  input  logic [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
  input  logic                          s_axi_wvalid,
  output logic                          s_axi_wready,
  output logic [1:0]                    s_axi_bresp,
  output logic                          s_axi_bvalid,
  input  logic                          s_axi_bready,
  input  logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
  input  logic                          s_axi_arvalid,
  output logic                          s_axi_arready,
  output logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
  output logic [1:0]                    s_axi_rresp,
  output logic                          s_axi_rvalid,
  input  logic                          s_axi_rready
);
  logic host_valid;
  logic host_write;
  logic [C_S_AXI_ADDR_WIDTH-1:0] host_addr;
  logic [C_S_AXI_DATA_WIDTH-1:0] host_wdata;
  logic [C_S_AXI_DATA_WIDTH/8-1:0] host_wstrb;
  logic host_ready;
  logic [C_S_AXI_DATA_WIDTH-1:0] host_rdata;
  logic host_error;

  axi_lite_frontend #(
    .ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .DATA_WIDTH(C_S_AXI_DATA_WIDTH)
  ) u_axi_lite_frontend (
    .s_axi_aclk,
    .s_axi_aresetn,
    .s_axi_awaddr,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_bready,
    .s_axi_araddr,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rvalid,
    .s_axi_rready,
    .host_valid,
    .host_write,
    .host_addr,
    .host_wdata,
    .host_wstrb,
    .host_ready,
    .host_rdata,
    .host_error
  );

  processor_host_wrapper u_processor_host_wrapper (
    .clk(s_axi_aclk),
    .rst_n(s_axi_aresetn),
    .host_valid,
    .host_write,
    .host_addr,
    .host_wdata,
    .host_wstrb,
    .host_ready,
    .host_rdata,
    .host_error
  );
endmodule
