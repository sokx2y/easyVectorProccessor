module axi_lite_frontend #(
  parameter int ADDR_WIDTH = 16,
  parameter int DATA_WIDTH = 32
) (
  input  logic                  s_axi_aclk,
  input  logic                  s_axi_aresetn,

  input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
  input  logic                  s_axi_awvalid,
  output logic                  s_axi_awready,
  input  logic [DATA_WIDTH-1:0] s_axi_wdata,
  input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
  input  logic                  s_axi_wvalid,
  output logic                  s_axi_wready,
  output logic [1:0]            s_axi_bresp,
  output logic                  s_axi_bvalid,
  input  logic                  s_axi_bready,

  input  logic [ADDR_WIDTH-1:0] s_axi_araddr,
  input  logic                  s_axi_arvalid,
  output logic                  s_axi_arready,
  output logic [DATA_WIDTH-1:0] s_axi_rdata,
  output logic [1:0]            s_axi_rresp,
  output logic                  s_axi_rvalid,
  input  logic                  s_axi_rready,

  output logic                  host_valid,
  output logic                  host_write,
  output logic [ADDR_WIDTH-1:0] host_addr,
  output logic [DATA_WIDTH-1:0] host_wdata,
  output logic [DATA_WIDTH/8-1:0] host_wstrb,
  input  logic                  host_ready,
  input  logic [DATA_WIDTH-1:0] host_rdata,
  input  logic                  host_error
);
  logic aw_pending;
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic w_pending;
  logic [DATA_WIDTH-1:0] wdata_reg;
  logic [DATA_WIDTH/8-1:0] wstrb_reg;
  logic ar_pending;
  logic [ADDR_WIDTH-1:0] araddr_reg;

  logic write_channel_idle;
  logic read_channel_idle;

  assign write_channel_idle =
    !host_valid && !s_axi_bvalid && !s_axi_rvalid && !ar_pending;
  assign read_channel_idle =
    !host_valid && !s_axi_bvalid && !s_axi_rvalid &&
    !aw_pending && !w_pending;

  // AW and W are captured independently, as required by AXI4-Lite.
  assign s_axi_awready = write_channel_idle && !aw_pending;
  assign s_axi_wready = write_channel_idle && !w_pending;
  // Give writes priority if read and write addresses are presented together.
  assign s_axi_arready =
    read_channel_idle && !ar_pending && !s_axi_awvalid && !s_axi_wvalid;

  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      aw_pending <= 1'b0;
      awaddr_reg <= '0;
      w_pending <= 1'b0;
      wdata_reg <= '0;
      wstrb_reg <= '0;
      ar_pending <= 1'b0;
      araddr_reg <= '0;
      host_valid <= 1'b0;
      host_write <= 1'b0;
      host_addr <= '0;
      host_wdata <= '0;
      host_wstrb <= '0;
      s_axi_bresp <= 2'b00;
      s_axi_bvalid <= 1'b0;
      s_axi_rdata <= '0;
      s_axi_rresp <= 2'b00;
      s_axi_rvalid <= 1'b0;
    end else begin
      if (s_axi_awvalid && s_axi_awready) begin
        aw_pending <= 1'b1;
        awaddr_reg <= s_axi_awaddr;
      end
      if (s_axi_wvalid && s_axi_wready) begin
        w_pending <= 1'b1;
        wdata_reg <= s_axi_wdata;
        wstrb_reg <= s_axi_wstrb;
      end
      if (s_axi_arvalid && s_axi_arready) begin
        ar_pending <= 1'b1;
        araddr_reg <= s_axi_araddr;
      end

      if (s_axi_bvalid && s_axi_bready)
        s_axi_bvalid <= 1'b0;
      if (s_axi_rvalid && s_axi_rready)
        s_axi_rvalid <= 1'b0;

      if (host_valid) begin
        if (host_ready) begin
          host_valid <= 1'b0;
          if (host_write) begin
            s_axi_bresp <= host_error ? 2'b10 : 2'b00;
            s_axi_bvalid <= 1'b1;
          end else begin
            s_axi_rdata <= host_rdata;
            s_axi_rresp <= host_error ? 2'b10 : 2'b00;
            s_axi_rvalid <= 1'b1;
          end
        end
      end else if (!s_axi_bvalid && !s_axi_rvalid) begin
        // Writes have priority once both independent channels are present.
        if (aw_pending && w_pending) begin
          host_valid <= 1'b1;
          host_write <= 1'b1;
          host_addr <= awaddr_reg;
          host_wdata <= wdata_reg;
          host_wstrb <= wstrb_reg;
          aw_pending <= 1'b0;
          w_pending <= 1'b0;
        end else if (ar_pending) begin
          host_valid <= 1'b1;
          host_write <= 1'b0;
          host_addr <= araddr_reg;
          host_wdata <= '0;
          host_wstrb <= '0;
          ar_pending <= 1'b0;
        end
      end
    end
  end
endmodule
