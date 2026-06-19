$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
python ..\scripts\gen_test_data.py
python ..\scripts\asm_to_mem.py ..\asm\matmul8x8.asm -o program.mem --listing program.lst
$rtl = @(
  "..\rtl\defs.sv", "..\rtl\pc.sv", "..\rtl\icm.sv", "..\rtl\decoder.sv",
  "..\rtl\imm_gen.sv", "..\rtl\scalar_rf.sv", "..\rtl\scalar_dcm.sv",
  "..\rtl\vector_rf.sv", "..\rtl\vector_dcm.sv", "..\rtl\scalar_mac.sv",
  "..\rtl\vector_mac.sv", "..\rtl\muxes.sv", "..\rtl\top.sv", "tb_top.sv"
)
& iverilog -g2012 -s tb_top -o simv @rtl
& vvp simv | Tee-Object -FilePath output.log
python ..\scripts\check_output.py output.log --expected expected_output.mem
