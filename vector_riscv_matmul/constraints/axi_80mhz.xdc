# Standalone AXI-Lite RTL top timing constraint used for implementation
# feasibility.  The final passing frequency is 80 MHz.
create_clock -name s_axi_aclk -period 12.500 [get_ports s_axi_aclk]

set data_inputs [get_ports -filter {
  DIRECTION == IN && NAME != s_axi_aclk && NAME != s_axi_aresetn
}]
set_input_delay 0.000 -clock s_axi_aclk $data_inputs
set_output_delay 0.000 -clock s_axi_aclk [all_outputs]
