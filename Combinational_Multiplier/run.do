vdel -all

vlib work

# Combinational Multiplier
vlog -source -lint combmultiplier.sv
vlog -source -lint combmultipliertb.sv

vopt top -o top_optimized +acc +cover=sbfec+NxN_multiplier(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save NxN_multiplier.ucdb
vcover report NxN_multiplier.ucdb
vcover report NxN_multiplier.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
