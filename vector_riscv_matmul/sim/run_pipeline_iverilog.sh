#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python ../scripts/gen_test_data.py
python ../scripts/asm_to_mem.py ../asm/matmul8x8.asm -o program.mem --listing program.lst
iverilog -g2012 -s tb_top_pipelined -o simv_pipeline \
  ../rtl/defs.sv ../rtl/pc.sv ../rtl/icm.sv ../rtl/decoder.sv \
  ../rtl/imm_gen.sv ../rtl/scalar_rf.sv ../rtl/scalar_dcm.sv \
  ../rtl/vector_rf.sv ../rtl/vector_dcm.sv ../rtl/scalar_mac.sv \
  ../rtl/vector_mac.sv ../rtl/muxes.sv ../rtl/pipeline_regs.sv \
  ../rtl/forwarding_unit.sv ../rtl/hazard_unit.sv ../rtl/top.sv \
  ../rtl/top_pipelined.sv tb_top_pipelined.sv
vvp simv_pipeline | tee output_pipeline.log
iverilog -g2012 -s tb_forwarding_unit -o simv_forwarding \
  ../rtl/forwarding_unit.sv tb_forwarding_unit.sv
vvp simv_forwarding | tee output_forwarding.log
