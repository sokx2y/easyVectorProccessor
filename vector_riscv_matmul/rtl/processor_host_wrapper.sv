module processor_host_wrapper (
  input  logic        clk,
  input  logic        rst_n,

  // Protocol-independent, single-beat Host request interface.
  input  logic        host_valid,
  input  logic        host_write,
  input  logic [15:0] host_addr,
  input  logic [31:0] host_wdata,
  input  logic [3:0]  host_wstrb,
  output logic        host_ready,
  output logic [31:0] host_rdata,
  output logic        host_error
);
  import vector_defs::*;

  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_ARM_RESET,
    STATE_RUN,
    STATE_DONE
  } state_t;

  state_t state;
  logic core_rst_n;
  logic core_halted;
  logic [15:0] core_pc;
  logic [31:0] cycle_count;
  logic access_error;

  logic host_accept;
  logic aligned;
  logic is_control;
  logic is_status;
  logic is_cycle_count;
  logic is_current_pc;
  logic is_version;
  logic is_icm;
  logic is_scalar;
  logic is_vector;
  logic memory_access;

  logic start_requested;
  logic soft_reset_requested;
  logic start_allowed;

  logic core_icm_we;
  logic [8:0] core_icm_addr;
  logic [31:0] core_icm_rdata;
  logic core_scalar_we;
  logic [7:0] core_scalar_addr;
  logic [31:0] core_scalar_rdata;
  logic core_vector_we;
  logic [7:0] core_vector_entry;
  logic [3:0] core_vector_lane;
  logic [31:0] core_vector_rdata;

  assign host_ready = 1'b1;
  assign host_accept = host_valid && host_ready;
  assign aligned = (host_addr[1:0] == 2'b00);

  assign is_control = (host_addr == HOST_CONTROL_ADDR);
  assign is_status = (host_addr == HOST_STATUS_ADDR);
  assign is_cycle_count = (host_addr == HOST_CYCLE_COUNT_ADDR);
  assign is_current_pc = (host_addr == HOST_CURRENT_PC_ADDR);
  assign is_version = (host_addr == HOST_VERSION_ADDR);
  assign is_icm = (host_addr >= HOST_ICM_BASE) &&
                  (host_addr <= HOST_ICM_END);
  assign is_scalar = (host_addr >= HOST_SCALAR_BASE) &&
                     (host_addr <= HOST_SCALAR_END);
  assign is_vector = (host_addr >= HOST_VECTOR_BASE) &&
                     (host_addr <= HOST_VECTOR_END);
  assign memory_access = is_icm || is_scalar || is_vector;

  assign start_allowed = (state == STATE_IDLE) || (state == STATE_DONE);
  assign start_requested =
    host_accept && host_write && is_control && aligned &&
    host_wstrb[0] && host_wdata[0] && !host_wdata[1] && start_allowed;
  assign soft_reset_requested =
    host_accept && host_write && is_control && aligned &&
    host_wstrb[0] && host_wdata[1];

  always_comb begin
    host_error = 1'b0;
    host_rdata = '0;

    core_icm_we = 1'b0;
    core_icm_addr = (host_addr - HOST_ICM_BASE) >> 2;
    core_scalar_we = 1'b0;
    core_scalar_addr = (host_addr - HOST_SCALAR_BASE) >> 2;
    core_vector_we = 1'b0;
    core_vector_entry = (host_addr - HOST_VECTOR_BASE) >> 6;
    core_vector_lane = host_addr[5:2];

    if (host_accept) begin
      if (!aligned) begin
        host_error = 1'b1;
      end else if (memory_access) begin
        if (state == STATE_RUN) begin
          host_error = 1'b1;
        end else begin
          if (is_icm) begin
            host_rdata = core_icm_rdata;
            core_icm_we = host_write;
          end else if (is_scalar) begin
            host_rdata = core_scalar_rdata;
            core_scalar_we = host_write;
          end else begin
            host_rdata = core_vector_rdata;
            core_vector_we = host_write;
          end
        end
      end else if (is_control) begin
        if (host_write) begin
          if (host_wstrb[0] && host_wdata[0] && !host_wdata[1] &&
              !start_allowed)
            host_error = 1'b1;
        end
      end else if (is_status) begin
        if (host_write)
          host_error = 1'b1;
        else begin
          host_rdata[0] = (state == STATE_DONE);
          host_rdata[1] = (state == STATE_RUN);
          host_rdata[2] = core_halted;
          host_rdata[3] = access_error;
          host_rdata[4] = (state == STATE_IDLE);
        end
      end else if (is_cycle_count) begin
        if (host_write)
          host_error = 1'b1;
        else
          host_rdata = cycle_count;
      end else if (is_current_pc) begin
        if (host_write)
          host_error = 1'b1;
        else
          host_rdata = {16'b0, core_pc};
      end else if (is_version) begin
        if (host_write)
          host_error = 1'b1;
        else
          host_rdata = HOST_VERSION_VALUE;
      end else begin
        host_error = 1'b1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
      cycle_count <= '0;
      access_error <= 1'b0;
    end else if (soft_reset_requested) begin
      state <= STATE_IDLE;
      cycle_count <= '0;
      access_error <= 1'b0;
    end else begin
      if (host_accept && host_error)
        access_error <= 1'b1;

      case (state)
        STATE_IDLE: begin
          if (start_requested) begin
            state <= STATE_ARM_RESET;
            cycle_count <= '0;
          end
        end
        STATE_ARM_RESET: state <= STATE_RUN;
        STATE_RUN: begin
          if (core_halted)
            state <= STATE_DONE;
          else
            cycle_count <= cycle_count + 1'b1;
        end
        STATE_DONE: begin
          if (start_requested) begin
            state <= STATE_ARM_RESET;
            cycle_count <= '0;
          end
        end
        default: state <= STATE_IDLE;
      endcase
    end
  end

  assign core_rst_n =
    rst_n && ((state == STATE_RUN) || (state == STATE_DONE));

  top_pipelined #(.USE_MEM_INIT(1'b0)) u_core (
    .clk,
    .rst_n(core_rst_n),
    .host_icm_we(core_icm_we),
    .host_icm_addr(core_icm_addr),
    .host_icm_wdata(host_wdata),
    .host_icm_wstrb(host_wstrb),
    .host_icm_rdata(core_icm_rdata),
    .host_scalar_we(core_scalar_we),
    .host_scalar_addr(core_scalar_addr),
    .host_scalar_wdata(host_wdata),
    .host_scalar_wstrb(host_wstrb),
    .host_scalar_rdata(core_scalar_rdata),
    .host_vector_we(core_vector_we),
    .host_vector_entry(core_vector_entry),
    .host_vector_lane(core_vector_lane),
    .host_vector_wdata(host_wdata),
    .host_vector_wstrb(host_wstrb),
    .host_vector_rdata(core_vector_rdata),
    .halted(core_halted),
    .dbg_pc(core_pc),
    .dbg_if_id_valid(),
    .dbg_if_id_instruction(),
    .dbg_id_ex_valid(),
    .dbg_id_ex_opcode(),
    .dbg_ex_wb_valid(),
    .dbg_ex_wb_opcode(),
    .dbg_scalar_rf_we(),
    .dbg_vector_rf_we(),
    .dbg_scalar_forward(),
    .dbg_vector_forward(),
    .dbg_vload_data(),
    .dbg_vmac_operand_before(),
    .dbg_vmac_operand_after(),
    .dbg_vmac_output(),
    .dbg_stall(),
    .dbg_bubble()
  );
endmodule
