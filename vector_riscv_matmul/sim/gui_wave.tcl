# Focused Vivado GUI waveform configuration for tb_pynq_axi.

add_wave /tb_pynq_axi/s_axi_aclk
add_wave /tb_pynq_axi/s_axi_aresetn

add_wave /tb_pynq_axi/s_axi_awaddr
add_wave /tb_pynq_axi/s_axi_awvalid
add_wave /tb_pynq_axi/s_axi_awready
add_wave /tb_pynq_axi/s_axi_wdata
add_wave /tb_pynq_axi/s_axi_wstrb
add_wave /tb_pynq_axi/s_axi_wvalid
add_wave /tb_pynq_axi/s_axi_wready
add_wave /tb_pynq_axi/s_axi_bresp
add_wave /tb_pynq_axi/s_axi_bvalid
add_wave /tb_pynq_axi/s_axi_bready

add_wave /tb_pynq_axi/s_axi_araddr
add_wave /tb_pynq_axi/s_axi_arvalid
add_wave /tb_pynq_axi/s_axi_arready
add_wave /tb_pynq_axi/s_axi_rdata
add_wave /tb_pynq_axi/s_axi_rresp
add_wave /tb_pynq_axi/s_axi_rvalid
add_wave /tb_pynq_axi/s_axi_rready

add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_valid
add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_write
add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_addr
add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_wdata
add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_ready
add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_rdata
add_wave /tb_pynq_axi/dut/u_axi_lite_frontend/host_error

add_wave /tb_pynq_axi/dut/u_processor_host_wrapper/state
add_wave /tb_pynq_axi/dut/u_processor_host_wrapper/cycle_count
add_wave /tb_pynq_axi/dut/u_processor_host_wrapper/core_halted
add_wave /tb_pynq_axi/dut/u_processor_host_wrapper/core_pc
add_wave /tb_pynq_axi/dut/u_processor_host_wrapper/access_error

run all
