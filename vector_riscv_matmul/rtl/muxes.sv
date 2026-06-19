module scalar_wb_mux #(
  parameter int WIDTH = 16
) (
  input  logic [2:0]       sel,
  input  logic [WIDTH-1:0] mem_data,
  input  logic [WIDTH-1:0] mov_data,
  input  logic [WIDTH-1:0] mac_data,
  output logic [WIDTH-1:0] out
);
  always_comb begin
    case (sel)
      3'd1: out = mem_data;
      3'd2: out = mov_data;
      3'd3: out = mac_data;
      default: out = '0;
    endcase
  end
endmodule

module vector_wb_mux #(
  parameter int WIDTH = 512
) (
  input  logic [2:0]       sel,
  input  logic [WIDTH-1:0] mem_data,
  input  logic [WIDTH-1:0] mac_data,
  output logic [WIDTH-1:0] out
);
  always_comb begin
    case (sel)
      3'd4: out = mem_data;
      3'd5: out = mac_data;
      default: out = '0;
    endcase
  end
endmodule
