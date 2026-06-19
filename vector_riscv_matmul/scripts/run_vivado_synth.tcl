read_verilog -sv [glob ../rtl/*.sv]
synth_design -top top -part xc7a35tcpg236-1
create_clock -name clk -period 10.000 [get_ports clk]
report_timing_summary -file timing_summary.rpt
report_utilization -file utilization.rpt
write_checkpoint -force vector_processor_synth.dcp
