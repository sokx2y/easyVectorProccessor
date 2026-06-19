#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python ../scripts/gen_test_data.py
python ../scripts/asm_to_mem.py ../asm/matmul8x8.asm -o program.mem --listing program.lst
verilator --binary --timing --trace --top-module tb_top \
  -Wno-fatal ../rtl/defs.sv ../rtl/pc.sv ../rtl/icm.sv ../rtl/decoder.sv \
  ../rtl/imm_gen.sv ../rtl/scalar_rf.sv ../rtl/scalar_dcm.sv \
  ../rtl/vector_rf.sv ../rtl/vector_dcm.sv ../rtl/scalar_mac.sv \
  ../rtl/vector_mac.sv ../rtl/muxes.sv ../rtl/top.sv tb_top.sv
./obj_dir/Vtb_top | tee output.log
python ../scripts/check_output.py output.log --expected expected_output.mem
