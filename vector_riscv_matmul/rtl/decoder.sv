module decoder (
  input  logic [31:0] instruction,
  output logic [3:0]  opcode,
  output logic [3:0]  rd,
  output logic [3:0]  rs1,
  output logic [3:0]  rs2,
  output logic        scalar_rf_we,
  output logic        vector_rf_we,
  output logic        scalar_mem_re,
  output logic        scalar_mem_we,
  output logic        vector_mem_re,
  output logic        vector_mem_we,
  output logic        scalar_mac_en,
  output logic        vector_mac_en,
  output logic        mac_reset,
  output logic        mov_high_sel,
  output logic        halt,
  output logic [2:0]  wb_sel
);
  import vector_defs::*;

  always_comb begin
    opcode          = instruction[31:28];
    rd              = instruction[27:24];
    rs1             = instruction[23:20];
    rs2             = instruction[19:16];
    scalar_rf_we    = 1'b0;
    vector_rf_we    = 1'b0;
    scalar_mem_re   = 1'b0;
    scalar_mem_we   = 1'b0;
    vector_mem_re   = 1'b0;
    vector_mem_we   = 1'b0;
    scalar_mac_en   = 1'b0;
    vector_mac_en   = 1'b0;
    mac_reset       = instruction[7];
    mov_high_sel    = instruction[7];
    halt            = 1'b0;
    wb_sel          = 3'd0;

    case (opcode)
      OP_LOAD: begin
        scalar_mem_re = 1'b1;
        scalar_rf_we  = 1'b1;
        wb_sel        = 3'd1;
      end
      OP_STORE: scalar_mem_we = 1'b1;
      OP_MOV: begin
        scalar_rf_we = 1'b1;
        wb_sel       = 3'd2;
      end
      OP_MAC: begin
        scalar_mac_en = 1'b1;
        scalar_rf_we  = 1'b1;
        wb_sel        = 3'd3;
      end
      OP_VLOAD: begin
        vector_mem_re = 1'b1;
        vector_rf_we  = 1'b1;
        wb_sel        = 3'd4;
      end
      OP_VSTORE: vector_mem_we = 1'b1;
      OP_VMACS: begin
        vector_mac_en = 1'b1;
        vector_rf_we  = 1'b1;
        wb_sel        = 3'd5;
      end
      OP_HALT: halt = 1'b1;
      default: ;
    endcase
  end
endmodule
