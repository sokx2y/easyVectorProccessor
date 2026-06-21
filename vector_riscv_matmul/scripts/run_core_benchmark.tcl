# Post-route core benchmark for a fair baseline/pipeline comparison.
#
# Usage:
#   vivado -mode batch -source scripts/run_core_benchmark.tcl \
#     -tclargs top 10.000
#   vivado -mode batch -source scripts/run_core_benchmark.tcl \
#     -tclargs top_pipelined 10.000
#
# Host/debug top-level paths are excluded from timing because they are inactive
# during processor execution.  Resource counts still include their RTL logic.

if {$argc < 1} {
  error "Expected core top name: top or top_pipelined"
}

set top_name [lindex $argv 0]
if {$top_name ni {top top_pipelined}} {
  error "Unsupported benchmark top: $top_name"
}

set clock_period_ns 10.000
if {$argc >= 2} {
  set clock_period_ns [lindex $argv 1]
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set rtl_dir    [file join $root_dir "rtl"]
set frequency_mhz [expr {round(1000.0 / $clock_period_ns)}]
set build_dir [file join $root_dir "vivado" "build" \
  "benchmark_${top_name}_${frequency_mhz}mhz"]

file mkdir $build_dir
cd $build_dir

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
  [file join $rtl_dir top.sv] \
  [file join $rtl_dir top_pipelined.sv] \
]

read_verilog -sv $rtl_files
synth_design -mode out_of_context -top $top_name \
  -part xc7z020clg400-1 -flatten_hierarchy rebuilt \
  -generic USE_MEM_INIT=0

create_clock -name clk -period $clock_period_ns [get_ports clk]
set_false_path -from [get_ports rst_n]
set data_inputs [get_ports -filter {
  DIRECTION == IN && NAME != clk && NAME != rst_n
}]
set_false_path -from $data_inputs
set_false_path -to [all_outputs]

opt_design
place_design
phys_opt_design
route_design

report_utilization -file utilization.rpt
report_utilization -hierarchical -file utilization_hierarchical.rpt
report_timing_summary -delay_type min_max -max_paths 20 \
  -file timing_summary.rpt
check_timing -verbose -file check_timing.rpt
report_power -file power_vectorless.rpt
write_checkpoint -force "${top_name}_routed.dcp"

set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path  [get_timing_paths -delay_type min -max_paths 1]
set setup_wns  [get_property SLACK $setup_path]
set hold_whs   [get_property SLACK $hold_path]
set estimated_period_ns [expr {$clock_period_ns - $setup_wns}]
set estimated_fmax_mhz  [expr {1000.0 / $estimated_period_ns}]

puts "CORE_BENCHMARK_COMPLETE top=$top_name"
puts "CORE_BENCHMARK_SETUP_WNS_NS=$setup_wns"
puts "CORE_BENCHMARK_HOLD_WHS_NS=$hold_whs"
puts [format "CORE_BENCHMARK_ESTIMATED_FMAX_MHZ=%.3f" \
  $estimated_fmax_mhz]
