vdel -all

vlib work

vlog -source -lint FFO32.sv
vlog -source -lint FFO32TB.sv

vlog -source -lint FFOp.sv
vlog -source -lint LZD2.sv
vlog -source -lint LZDn.sv

vopt top -o top_optimized +acc +cover=sbfec+FFO32(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save FFO32.ucdb
vcover report FFO32.ucdb
vcover report FFO32.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
