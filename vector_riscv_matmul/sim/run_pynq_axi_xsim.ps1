$ErrorActionPreference = "Stop"
$simDir = $PSScriptRoot
$root = (Resolve-Path (Join-Path $simDir "..")).Path

python (Join-Path $root "scripts\gen_test_data.py")
python (Join-Path $root "scripts\asm_to_mem.py") `
  (Join-Path $root "asm\matmul8x8.asm") `
  -o (Join-Path $simDir "program.mem") `
  --listing (Join-Path $simDir "program.lst")
if ($LASTEXITCODE -ne 0) { throw "test-data generation failed" }

$work = Join-Path $env:TEMP ("vector_proc_axi_" + [guid]::NewGuid().ToString("N"))
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
  "forwarding_unit.sv", "hazard_unit.sv", "top_pipelined.sv",
  "processor_host_wrapper.sv", "axi_lite_frontend.sv",
  "pynq_vector_processor_ip.sv"
) | ForEach-Object { Join-Path $root ("rtl\" + $_) }
$rtl += Join-Path $simDir "tb_pynq_axi.sv"

Push-Location $work
try {
  & xvlog -sv @rtl
  if ($LASTEXITCODE -ne 0) { throw "xvlog failed" }
  & xelab --relax tb_pynq_axi -s tb_pynq_axi_sim
  if ($LASTEXITCODE -ne 0) { throw "xelab failed" }
  & xsim tb_pynq_axi_sim -runall |
    Tee-Object -FilePath (Join-Path $work "output_axi.log")
  if ($LASTEXITCODE -ne 0) { throw "xsim failed" }
} finally {
  Pop-Location
}

Copy-Item -Force (Join-Path $work "output_axi.log") `
  (Join-Path $simDir "output_axi.log")
Copy-Item -Force (Join-Path $work "dump_axi.vcd") `
  (Join-Path $simDir "dump_axi.vcd")
