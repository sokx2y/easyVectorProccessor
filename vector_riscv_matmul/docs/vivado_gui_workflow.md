# Vivado GUI workflow

No physical PYNQ board is required for this course workflow. Vivado GUI is
used to inspect behavioral waveforms and the generated implementation
reports.

## Create or recreate the project

From the repository root:

```powershell
vivado -mode batch -source scripts/create_vivado_gui_project.tcl
```

Open:

```text
vivado/gui_vector_processor/gui_vector_processor.xpr
```

The project uses:

- part `xc7z020clg400-1`;
- design top `pynq_vector_processor_ip`;
- simulation top `tb_pynq_axi`;
- 80 MHz constraint `constraints/axi_80mhz.xdc`.

## Behavioral waveform

In Flow Navigator select:

```text
Simulation -> Run Simulation -> Run Behavioral Simulation
```

The project automatically loads the focused AXI/controller waveform list and
runs until completion. The Tcl Console must print:

```text
AXI PIPELINED_CYCLES=237
PYNQ_AXI PASS
```

Useful signals to add to the wave window:

- AXI write: `s_axi_awvalid`, `s_axi_awready`, `s_axi_wvalid`,
  `s_axi_wready`, `s_axi_bvalid`, `s_axi_bresp`;
- AXI read: `s_axi_arvalid`, `s_axi_arready`, `s_axi_rvalid`,
  `s_axi_rready`, `s_axi_rdata`, `s_axi_rresp`;
- Host bridge: `host_valid`, `host_write`, `host_addr`, `host_rdata`,
  `host_error`;
- controller: `state`, `cycle_count`, `core_halted`, `core_pc`.

For the report, capture one waveform showing an AXI memory write and one
showing START, BUSY, HALT/DONE, and the 237-cycle count.

## Reports

The authoritative automated reports are under:

```text
vivado/build/axi_synth
vivado/build/axi_impl
vivado/build/axi_impl_80mhz
vivado/build/benchmark_top_100mhz
vivado/build/benchmark_top_pipelined_100mhz
```

Open a routed `.dcp` through `File -> Checkpoint -> Open` to inspect Device,
Timing, Utilization, and Power views. The 80 MHz routed checkpoint is:

```text
vivado/build/axi_impl_80mhz/pynq_vector_processor_ip_routed.dcp
```

Do not generate a bitstream from the standalone AXI top. The expected
`NSTD-1`, `UCIO-1`, and `ZPS7-1` warnings exist because there is intentionally
no board-level pin map or Zynq PS Block Design.
