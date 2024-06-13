vdel -all

vlib work

# Memory Zero Controller
vlog -source -lint memoryzero.sv
vlog -source -lint fsmtb.sv

vopt top -o top_optimized +acc +cover=sbfec+mz(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save mz.ucdb
vcover report mz.ucdb
vcover report mz.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
