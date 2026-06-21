# Create a Vivado 2023.2 RTL project for GUI waveform inspection and reports.
#
# Usage:
#   vivado -mode batch -source scripts/create_vivado_gui_project.tcl
# Then open:
#   vivado/gui_vector_processor/gui_vector_processor.xpr

set script_dir  [file dirname [file normalize [info script]]]
set root_dir    [file normalize [file join $script_dir ".."]]
set project_dir [file join $root_dir "vivado" "gui_vector_processor"]
set project_name gui_vector_processor

create_project -force $project_name $project_dir \
  -part xc7z020clg400-1

set rtl_dir [file join $root_dir "rtl"]
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
  [file join $rtl_dir processor_host_wrapper.sv] \
  [file join $rtl_dir axi_lite_frontend.sv] \
  [file join $rtl_dir pynq_vector_processor_ip.sv] \
]
add_files -norecurse -fileset sources_1 $rtl_files
set_property top pynq_vector_processor_ip [get_filesets sources_1]

add_files -norecurse -fileset constrs_1 \
  [file join $root_dir "constraints" "axi_80mhz.xdc"]

set sim_dir [file join $root_dir "sim"]
set sim_files [list \
  [file join $sim_dir tb_top.sv] \
  [file join $sim_dir tb_top_pipelined.sv] \
  [file join $sim_dir tb_forwarding_unit.sv] \
  [file join $sim_dir tb_memory_host.sv] \
  [file join $sim_dir tb_processor_host_wrapper.sv] \
  [file join $sim_dir tb_pynq_axi.sv] \
  [file join $sim_dir program.mem] \
  [file join $sim_dir scalar_init.mem] \
  [file join $sim_dir vector_init.mem] \
  [file join $sim_dir expected_output.mem] \
]
add_files -norecurse -fileset sim_1 $sim_files
set_property top tb_pynq_axi [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
set_property xsim.simulate.custom_tcl \
  [file join $sim_dir "gui_wave.tcl"] [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "GUI_PROJECT_COMPLETE"
puts "GUI_PROJECT_FILE=[file join $project_dir ${project_name}.xpr]"
close_project
