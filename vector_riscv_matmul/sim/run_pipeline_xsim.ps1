$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

python ..\scripts\gen_test_data.py
python ..\scripts\asm_to_mem.py ..\asm\matmul8x8.asm -o program.mem --listing program.lst

$rtl = @(
  "..\rtl\defs.sv", "..\rtl\pc.sv", "..\rtl\icm.sv", "..\rtl\decoder.sv",
  "..\rtl\imm_gen.sv", "..\rtl\scalar_rf.sv", "..\rtl\scalar_dcm.sv",
  "..\rtl\vector_rf.sv", "..\rtl\vector_dcm.sv", "..\rtl\scalar_mac.sv",
  "..\rtl\vector_mac.sv", "..\rtl\muxes.sv", "..\rtl\pipeline_regs.sv",
  "..\rtl\forwarding_unit.sv", "..\rtl\hazard_unit.sv", "..\rtl\top.sv",
  "..\rtl\top_pipelined.sv", "tb_top_pipelined.sv"
)

& xvlog -sv @rtl
& xelab --relax tb_top_pipelined -s tb_top_pipelined_sim
& xsim tb_top_pipelined_sim -runall | Tee-Object -FilePath output_pipeline.log

& xvlog -sv ..\rtl\forwarding_unit.sv tb_forwarding_unit.sv
& xelab --relax tb_forwarding_unit -s tb_forwarding_unit_sim
& xsim tb_forwarding_unit_sim -runall | Tee-Object -FilePath output_forwarding.log
