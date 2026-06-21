# Vivado 2023.2 non-project synthesis flow for the AXI-Lite deployment top.
#
# Usage:
#   vivado -mode batch -source scripts/run_vivado_synth.tcl
#
# The generated build directory is intentionally disposable.  Human-readable
# reports are copied into reports/ by later documentation steps.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set rtl_dir    [file join $root_dir "rtl"]
set build_dir  [file join $root_dir "vivado" "build" "axi_synth"]

file mkdir $build_dir
cd $build_dir

set part_name xc7z020clg400-1
set top_name  pynq_vector_processor_ip

set rtl_files [list \
  [file join $rtl_dir defs.sv] \
  [file join $rtl_dir pc.sv] \
  [file join $rtl_dir icm.sv] \
  [file join $rtl_dir decoder.sv] \
  [file join $rtl_dir imm_gen.sv] \
  [file join $rtl_dir scalar_rf.sv] \
  [file join $rtl_dir scalar_dcm.sv] \
  [file join $rtl_dir vector_rf.sv] \
  [file join $rtl_dir vector_dcm.sv] \
  [file join $rtl_dir scalar_mac.sv] \
  [file join $rtl_dir vector_mac.sv] \
  [file join $rtl_dir muxes.sv] \
  [file join $rtl_dir pipeline_regs.sv] \
  [file join $rtl_dir forwarding_unit.sv] \
  [file join $rtl_dir hazard_unit.sv] \
  [file join $rtl_dir top_pipelined.sv] \
  [file join $rtl_dir processor_host_wrapper.sv] \
  [file join $rtl_dir axi_lite_frontend.sv] \
  [file join $rtl_dir pynq_vector_processor_ip.sv] \
]

read_verilog -sv $rtl_files
synth_design -top $top_name -part $part_name -flatten_hierarchy rebuilt

create_clock -name s_axi_aclk -period 10.000 [get_ports s_axi_aclk]
set data_inputs [get_ports -filter {
  DIRECTION == IN && NAME != s_axi_aclk && NAME != s_axi_aresetn
}]
set_input_delay  0.000 -clock s_axi_aclk $data_inputs
set_output_delay 0.000 -clock s_axi_aclk [all_outputs]

report_utilization -file utilization_synth.rpt
report_utilization -hierarchical -file utilization_hierarchical_synth.rpt
report_timing_summary -delay_type min_max -max_paths 10 \
  -file timing_summary_synth.rpt
report_clock_utilization -file clock_utilization_synth.rpt
check_timing -verbose -file check_timing_synth.rpt
write_checkpoint -force pynq_vector_processor_ip_synth.dcp

puts "SYNTHESIS_COMPLETE top=$top_name part=$part_name"
