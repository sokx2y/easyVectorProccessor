# Vivado 2023.2 non-project implementation flow for the AXI-Lite RTL top.
#
# This is an implementation feasibility run for an IP-style top.  It does not
# generate a board bitstream because no physical board or package-pin mapping
# is required by the course workflow.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set synth_dir  [file join $root_dir "vivado" "build" "axi_synth"]
set synth_dcp  [file join $synth_dir "pynq_vector_processor_ip_synth.dcp"]

set clock_period_ns 10.000
if {$argc >= 1} {
  set clock_period_ns [lindex $argv 0]
}
set frequency_mhz [expr {round(1000.0 / $clock_period_ns)}]
set build_dir [file join $root_dir "vivado" "build" \
  "axi_impl_${frequency_mhz}mhz"]

if {![file exists $synth_dcp]} {
  error "Missing synthesis checkpoint: $synth_dcp"
}

file mkdir $build_dir
cd $build_dir

open_checkpoint $synth_dcp

# Replace the synthesis checkpoint's 100 MHz timing constraints so the same
# netlist can be evaluated at the requested fallback frequency.
reset_timing
create_clock -name s_axi_aclk -period $clock_period_ns \
  [get_ports s_axi_aclk]
set data_inputs [get_ports -filter {
  DIRECTION == IN && NAME != s_axi_aclk && NAME != s_axi_aresetn
}]
set_input_delay  0.000 -clock s_axi_aclk $data_inputs
set_output_delay 0.000 -clock s_axi_aclk [all_outputs]

opt_design
place_design
phys_opt_design
route_design

report_utilization -file utilization_impl.rpt
report_utilization -hierarchical -file utilization_hierarchical_impl.rpt
report_timing_summary -delay_type min_max -max_paths 20 \
  -file timing_summary_impl.rpt
report_clock_utilization -file clock_utilization_impl.rpt
check_timing -verbose -file check_timing_impl.rpt
report_drc -file drc_impl.rpt
report_power -file power_vectorless_impl.rpt
write_checkpoint -force pynq_vector_processor_ip_routed.dcp

set setup_paths [get_timing_paths -delay_type max -max_paths 1]
set hold_paths  [get_timing_paths -delay_type min -max_paths 1]
set setup_wns   [get_property SLACK $setup_paths]
set hold_whs    [get_property SLACK $hold_paths]

puts "IMPLEMENTATION_COMPLETE"
puts "IMPLEMENTATION_FREQUENCY_MHZ=$frequency_mhz"
puts "IMPLEMENTATION_SETUP_WNS_NS=$setup_wns"
puts "IMPLEMENTATION_HOLD_WHS_NS=$hold_whs"
