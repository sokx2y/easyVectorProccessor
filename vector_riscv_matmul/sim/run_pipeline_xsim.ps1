$ErrorActionPreference = "Stop"
$simDir = $PSScriptRoot
$root = (Resolve-Path (Join-Path $simDir "..")).Path

python (Join-Path $root "scripts\gen_test_data.py")
if ($LASTEXITCODE -ne 0) { throw "test-data generation failed" }
python (Join-Path $root "scripts\asm_to_mem.py") `
  (Join-Path $root "asm\matmul8x8.asm") `
  -o (Join-Path $simDir "program.mem") `
  --listing (Join-Path $simDir "program.lst")
if ($LASTEXITCODE -ne 0) { throw "assembly failed" }

$work = Join-Path $env:TEMP ("vector_proc_pipeline_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null
Copy-Item -Force `
  (Join-Path $simDir "program.mem"), `
  (Join-Path $simDir "scalar_init.mem"), `
  (Join-Path $simDir "vector_init.mem"), `
  (Join-Path $simDir "expected_output.mem") `
  -Destination $work

$rtl = @(
  "defs.sv", "pc.sv", "icm.sv", "decoder.sv", "imm_gen.sv",
  "scalar_rf.sv", "scalar_dcm.sv", "vector_rf.sv", "vector_dcm.sv",
  "scalar_mac.sv", "vector_mac.sv", "muxes.sv", "pipeline_regs.sv",
  "forwarding_unit.sv", "hazard_unit.sv", "top.sv", "top_pipelined.sv"
) | ForEach-Object { Join-Path $root ("rtl\" + $_) }
$pipelineRtl = $rtl + (Join-Path $simDir "tb_top_pipelined.sv")

Push-Location $work
try {
  & xvlog -sv @pipelineRtl
  if ($LASTEXITCODE -ne 0) { throw "pipeline xvlog failed" }
  & xelab --relax tb_top_pipelined -s tb_top_pipelined_sim
  if ($LASTEXITCODE -ne 0) { throw "pipeline xelab failed" }
  & xsim tb_top_pipelined_sim -runall |
    Tee-Object -FilePath (Join-Path $work "output_pipeline.log")
  if ($LASTEXITCODE -ne 0) { throw "pipeline xsim failed" }

  & xvlog -sv `
    (Join-Path $root "rtl\forwarding_unit.sv") `
    (Join-Path $simDir "tb_forwarding_unit.sv")
  if ($LASTEXITCODE -ne 0) { throw "forwarding xvlog failed" }
  & xelab --relax tb_forwarding_unit -s tb_forwarding_unit_sim
  if ($LASTEXITCODE -ne 0) { throw "forwarding xelab failed" }
  & xsim tb_forwarding_unit_sim -runall |
    Tee-Object -FilePath (Join-Path $work "output_forwarding.log")
  if ($LASTEXITCODE -ne 0) { throw "forwarding xsim failed" }
} finally {
  Pop-Location
}

Copy-Item -Force (Join-Path $work "output_pipeline.log") `
  (Join-Path $simDir "output_pipeline.log")
Copy-Item -Force (Join-Path $work "output_forwarding.log") `
  (Join-Path $simDir "output_forwarding.log")
