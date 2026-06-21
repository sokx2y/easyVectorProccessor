# Batch-check the same behavioral simulation configured for Vivado GUI.

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_file [file join $root_dir "vivado" "gui_vector_processor" \
  "gui_vector_processor.xpr"]

if {![file exists $project_file]} {
  error "Create the GUI project first: $project_file"
}

open_project $project_file
launch_simulation -simset sim_1 -mode behavioral
close_sim -force
close_project
puts "GUI_BEHAVIORAL_SIM_COMPLETE"
