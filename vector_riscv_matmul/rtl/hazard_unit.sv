// All current one-cycle RAW hazards are handled by WB-to-ID and WB-to-EX
// forwarding. The unit centralizes pipeline stop/flush policy for extension
// to synchronous or variable-latency memories.
module hazard_unit (
  input  logic halt_in_id,
  input  logic memory_busy,
  output logic stall,
  output logic flush_if
);
  always_comb begin
    stall = memory_busy;
    flush_if = halt_in_id;
  end
endmodule
