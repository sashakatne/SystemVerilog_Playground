vdel -all

vlib work

# Arbiter verification with Assertions
vlog -source -lint arbiter.sv
vlog -source -lint assertions.sv
vlog -source -lint top.sv

vopt top -o top_optimized +acc +cover=sbfec+Arbiter(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save Arbiter.ucdb
vcover report Arbiter.ucdb
vcover report Arbiter.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
