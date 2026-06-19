set rtl [glob ../rtl/*.sv]
exec xvlog -sv {*}$rtl tb_top.sv
exec xelab --relax tb_top -s tb_top_sim
exec xsim tb_top_sim -runall
