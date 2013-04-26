transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/seven_segment.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/sign_extension.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/pll.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/writeback.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/memory.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/execute.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/decode.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/lg_highlevel.v}
vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/fetch.v}

vlog -vlog01compat -work work +incdir+C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly {C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/lg_highlevel.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  lg_highlevel

do C:/Users/Chris/Dropbox/GitHub/CS3220_GPU/hw6_cpuonly/simulation/modelsim/my_custom_view.do
