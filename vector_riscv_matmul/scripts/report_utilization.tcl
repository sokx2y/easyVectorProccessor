set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set dcp [file join $root_dir "vivado" "build" "axi_impl_80mhz" \
  "pynq_vector_processor_ip_routed.dcp"]
open_checkpoint $dcp
report_utilization -hierarchical -file [file join [file dirname $dcp] \
  "utilization_hierarchical_impl.rpt"]
