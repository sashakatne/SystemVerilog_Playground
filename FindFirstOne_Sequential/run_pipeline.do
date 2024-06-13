vdel -all

vlib work

# Pipelined FFO32
vlog -source -lint FFO32.sv
vlog -source -lint FFO32p.sv

vlog -source -lint FFO32ptb.sv
# vlog -source -lint +define+DEBUG FFO32ptb.sv

vopt top -o top_optimized +acc +cover=sbfec+FFO32p(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save FFO32p.ucdb
vcover report FFO32p.ucdb
vcover report FFO32p.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
