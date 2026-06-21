$ErrorActionPreference = "Stop"
$simDir = $PSScriptRoot
$root = (Resolve-Path (Join-Path $simDir "..")).Path
$work = Join-Path $env:TEMP ("vector_proc_memory_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null

$rtl = @(
  (Join-Path $root "rtl\icm.sv"),
  (Join-Path $root "rtl\scalar_dcm.sv"),
  (Join-Path $root "rtl\vector_dcm.sv"),
  (Join-Path $simDir "tb_memory_host.sv")
)

Push-Location $work
try {
  & xvlog -sv @rtl
  if ($LASTEXITCODE -ne 0) { throw "xvlog failed" }
  & xelab --relax tb_memory_host -s tb_memory_host_sim
  if ($LASTEXITCODE -ne 0) { throw "xelab failed" }
  & xsim tb_memory_host_sim -runall |
    Tee-Object -FilePath (Join-Path $work "output_memory_host.log")
  if ($LASTEXITCODE -ne 0) { throw "xsim failed" }
} finally {
  Pop-Location
}

Copy-Item -Force (Join-Path $work "output_memory_host.log") `
  (Join-Path $simDir "output_memory_host.log")
